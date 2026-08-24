FROM public.ecr.aws/lambda/python:3.12

# Copy requirements and install dependencies
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r requirements.txt

# The Runtime Interface Emulator runs only when AWS_LAMBDA_RUNTIME_API is unset,
# which never holds in a deployed Lambda, so it is unreachable here. Removing it
# keeps its Go stdlib CVEs out of our scan surface.
RUN rm -f /usr/local/bin/aws-lambda-rie

# Copy handler code
COPY handler.py ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD [ "handler.lambda_handler" ]

