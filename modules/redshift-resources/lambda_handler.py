import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

BEDROCK_RUNTIME_CLIENT = boto3.client("bedrock-runtime")
DEFAULT_MODEL_PARAMS = {
    "maxTokens": 512,
    "temperature": 0.7,
    "topP": 0.9,
}


def lambda_handler(event: dict, context: dict) -> dict:
    """
    Lambda handler for Redshift External Function that invokes Claude models via Bedrock Converse API.
    
    Expected event format (Redshift External Function):
    {
        "user": "awsuser",
        "cluster": "arn:aws:redshift:...",
        "database": "dev",
        "external_function": "invoke_bedrock_claude",
        "query_id": 13228310,
        "request_id": "33d56e72-f9bc-4990-9eb8-ab41e67db1fa",
        "arguments": [
            ["model_id", "prompt", "model_params", "tool_config"],
            ["model_id", "prompt", "model_params", "tool_config"],
            ...
        ],
        "num_records": 5
    }
    
    Returns:
    {
        "results": [
            "result1",
            "result2",
            ...
        ]
    }
    """
    arguments = event.get("arguments", [])
    num_records = event.get("num_records", len(arguments))
    logger.info(f"Processing {num_records} records")
    results = [json.dumps(_process_arguments(arg_set)) for arg_set in arguments]
    return json.dumps({"results": results})


def _process_arguments(arg_set: list) -> dict:
    """
    Process a single argument set from Redshift.
    Function signature: invoke_bedrock_claude(model_id, prompt, model_params, tool_config)
    Arguments are passed as: [model_id, prompt, model_params, tool_config]
    """
    if len(arg_set) < 2:
        raise ValueError(f"Expected at least 2 arguments, got {len(arg_set)}")
    
    model_id = arg_set[0]
    prompt = arg_set[1]
    model_params_raw = arg_set[2] if len(arg_set) > 2 else None
    tool_config_raw = arg_set[3] if len(arg_set) > 3 else None
    
    # Parse JSON strings if they were passed as strings (Redshift passes VARCHAR as strings)
    model_params = json.loads(model_params_raw) if isinstance(model_params_raw, str) else (model_params_raw or {})
    tool_config = json.loads(tool_config_raw) if isinstance(tool_config_raw, str) else (tool_config_raw or {})
    
    return _invoke_bedrock(
        model_id=model_id,
        prompt=prompt,
        model_params=model_params,
        tool_config=tool_config
    )


def _invoke_bedrock(
    model_id: str,
    prompt: str,
    model_params: dict | None = {},
    tool_config: dict | None = None
) -> dict:
    """
    Invoke Claude model via Amazon Bedrock Converse API with the given prompt and parameters.
    
    Args:
        model_id: The Claude Bedrock model ID (e.g., "anthropic.claude-3-sonnet-20240229-v1:0")
        prompt: The formatted prompt text
        model_params: Optional model-specific parameters (maxTokens, temperature, topP)
        tool_config: Optional tool configuration with 'tools' array and 'toolChoice'
        
    Returns:
        Dictionary containing the model response
    """
    request_params = {
        "modelId": model_id,
        "messages": [
            {
                "role": "user",
                "content": [{"text": prompt}]
            }
        ],
        "inferenceConfig": {
            "maxTokens": model_params.get("maxTokens", DEFAULT_MODEL_PARAMS["maxTokens"]),
            "temperature": model_params.get("temperature", DEFAULT_MODEL_PARAMS["temperature"]),
            "topP": model_params.get("topP", DEFAULT_MODEL_PARAMS["topP"]),
        }
    }
    
    if tool_config:
        request_params["toolConfig"] = tool_config
    
    response = BEDROCK_RUNTIME_CLIENT.converse(**request_params)
    return _extract_output(response)


def _extract_output(response: dict) -> dict:
    """
    Extract the output from the Bedrock Converse API response.
    If a tool was used, return the tool input directly. Otherwise, return the output text.
    """
    # The response structure is: response['output']['message']['content']
    output_message = response.get("output", {}).get("message", {})
    content = output_message.get("content", [])
    
    # Extract text from content array (content is a list of content blocks)
    # When tools are used, content may contain toolUse blocks instead of text blocks
    output_text = ""
    tool_input = None
    
    for block in content:
        if block.get("text"):
            output_text += block["text"]
        elif block.get("toolUse"):
            # Extract tool use response - this contains the structured output
            tool_use = block["toolUse"]
            # If tool was used, return the tool input directly
            if tool_use.get("input"):
                tool_input = tool_use.get("input")
                break  # Use the first tool input found
    
    # If a tool was used, return the tool input directly
    if tool_input:
        return tool_input
    
    # Otherwise return text output
    return {"output_text": output_text}

