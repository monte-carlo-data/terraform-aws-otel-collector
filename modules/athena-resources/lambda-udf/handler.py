import json
import logging
from typing import Any

import boto3
from athena_udf import BaseAthenaUDF
from pyarrow import Schema

logger = logging.getLogger()
logger.setLevel("INFO")

BEDROCK_RUNTIME_CLIENT = boto3.client("bedrock-runtime")


class BedrockClaudeUDF(BaseAthenaUDF):
    """
    Athena UDF that invokes Claude models via Bedrock Converse API.

    Function signature: mcd_invoke_bedrock(model_id, prompt, model_params, tool_config)
    - model_id: VARCHAR - The Claude Bedrock model ID
    - prompt: VARCHAR - The formatted prompt text
    - model_params: VARCHAR - Optional JSON string with inference config (maxTokens, temperature, topP, etc.)
    - tool_config: VARCHAR - Optional JSON string with tool configuration
    """

    @staticmethod
    def handle_athena_record(
        input_schema: Schema,
        output_schema: Schema,
        arguments: list[Any]
    ) -> str:
        """
        Process a single record from Athena.

        Args:
            input_schema: PyArrow schema for input data
            output_schema: PyArrow schema for output data
            arguments: List of function arguments
                - arguments[0]: model_id (str)
                - arguments[1]: prompt (str)
                - arguments[2]: model_params (str, optional JSON string)
                - arguments[3]: tool_config (str, optional JSON string)

        Returns:
            JSON string containing the model response
        """
        if len(arguments) < 2:
            error_msg = f"Expected at least 2 arguments (model_id, prompt), got {len(arguments)}"
            logger.error(error_msg)
            return json.dumps({"error": error_msg})

        model_id = str(arguments[0]) if arguments[0] is not None else None
        prompt = str(arguments[1]) if arguments[1] is not None else None
        model_params_raw = str(arguments[2]) if len(arguments) > 2 and arguments[2] is not None else None
        tool_config_raw = str(arguments[3]) if len(arguments) > 3 and arguments[3] is not None else None

        if not model_id or not prompt:
            error_msg = "model_id and prompt are required"
            logger.error(error_msg)
            return json.dumps({"error": error_msg})

        try:
            # Parse JSON strings if they were passed as strings
            model_params = json.loads(model_params_raw) if model_params_raw else {}
            tool_config = json.loads(tool_config_raw) if tool_config_raw else {}

            result = _invoke_bedrock(
                model_id=model_id,
                prompt=prompt,
                model_params=model_params,
                tool_config=tool_config
            )

            # Return as JSON string (VARCHAR return type)
            return json.dumps(result)

        except json.JSONDecodeError as e:
            error_msg = f"Failed to parse JSON parameters: {e}"
            logger.error(error_msg, exc_info=True)
            return json.dumps({"error": error_msg})
        except Exception as e:
            error_msg = f"Error invoking Bedrock: {e}"
            logger.error(error_msg, exc_info=True)
            return json.dumps({"error": error_msg})


def _invoke_bedrock(
    model_id: str,
    prompt: str,
    model_params: dict | None = None,
    tool_config: dict | None = None
) -> dict:
    """
    Invoke Claude model via Amazon Bedrock Converse API with the given prompt and parameters.

    Args:
        model_id: The Claude Bedrock model ID (e.g., "anthropic.claude-3-sonnet-20240229-v1:0")
        prompt: The formatted prompt text
        model_params: Optional model-specific parameters (e.g. maxTokens, temperature, topP)
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
    }

    if model_params:
        request_params["inferenceConfig"] = model_params

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


# Create the lambda_handler using the BaseAthenaUDF class
# You can configure threading options here if needed:
# - use_threads: Enable/disable multithreading (default: True)
# - chunk_size: Force splitting record batches into chunks
# - max_workers: ThreadPoolExecutor max workers
lambda_handler = BedrockClaudeUDF(use_threads=True).lambda_handler
