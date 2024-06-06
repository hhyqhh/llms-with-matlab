# Large Language Models (LLMs) with MATLAB®

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab-deep-learning/llms-with-matlab) [![View Large Language Models (LLMs) with MATLAB on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/163796-large-language-models-llms-with-matlab) 

This repository contains example code to demonstrate how to connect MATLAB to the OpenAI™ Chat Completions API (which powers ChatGPT™), OpenAI Images API (which powers DALL·E™), [Azure® OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/), and local [Ollama](https://ollama.com/) models. This allows you to leverage the natural language processing capabilities of large language models directly within your MATLAB environment.

## OpenAI and Azure

The functionality shown here serves as an interface to the APIs listed above. To start using the OpenAI APIs, you first need to obtain OpenAI API keys; to use Azure OpenAI Services, you need to create a model deployment on your Azure account and obtain one of the keys for it. You are responsible for any fees OpenAI or Azure may charge for the use of their APIs. You should be familiar with the limitations and risks associated with using this technology, and you agree that you shall be solely responsible for full compliance with any terms that may apply to your use of the OpenAI or Azure APIs.

Some of the current LLMs supported on Azure and OpenAI are:
- gpt-3.5-turbo, gpt-3.5-turbo-1106, gpt-3.5-turbo-0125
- gpt-4o, gpt-4o-2024-05-13 (GPT-4 Omni)
- gpt-4-turbo, gpt-4-turbo-2024-04-09 (GPT-4 Turbo with Vision)
- gpt-4, gpt-4-0613
- dall-e-2, dall-e-3
                                                        
For details on the specification of each model, check the official [OpenAI documentation](https://platform.openai.com/docs/models).

## Ollama

To use local models with [Ollama](https://ollama.com/), you will need to install and start an Ollama server, and “pull” models into it. Please follow the Ollama documentation for details. You should be familiar with the limitations and risks associated with using this technology, and you agree that you shall be solely responsible for full compliance with any terms that may apply to your use of any specific model.

Some of the [LLMs currently supported out of the box on Ollama](https://ollama.com/library) are:
- llama2, llama2-uncensored, llama3, codellama
- phi3
- aya
- mistral (v0.1, v0.2, v0.3)
- mixtral
- gemma, codegemma
- command-r

## Requirements

### MathWorks Products (https://www.mathworks.com)

- Requires MATLAB release R2024a or newer.
- Some examples require Text Analytics Toolbox™.

### 3rd Party Products:

- For OpenAI connections: An active OpenAI API subscription and API key.
- For Azure OpenAI Services: An active Azure subscription with OpenAI access, deployment, and API key.
- For Ollama: A local Ollama installation. Currently, only connections on `localhost` are supported, i.e., Ollama and MATLAB must run on the same machine.

## Setup

### MATLAB Online

To use this repository with MATLAB Online, click [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab-deep-learning/llms-with-matlab)


### MATLAB Desktop

To use this repository with a local installation of MATLAB, first clone the repository. 

1. In the system command prompt, run:

    ```bash
    git clone https://github.com/matlab-deep-learning/llms-with-matlab.git
    ```
   
2. Open MATLAB and navigate to the directory where you cloned the repository.

3. Add the directory to the MATLAB path.

    ```matlab
    addpath('path/to/llms-with-matlab');
    ```

### Setting up your OpenAI API key

Set up your OpenAI API key. Create a `.env` file in the project root directory with the following content.

```
OPENAI_API_KEY=<your key>
```

Then load your `.env` file as follows:

```matlab
loadenv(".env")
```

### Setting up your Azure OpenAI Services API key

Set up your OpenAI API key. Create a `.env` file in the project root directory with the following content.

```
AZURE_OPENAI_API_KEY=<your key>
```

You can use either `KEY1` or `KEY2` from the Azure configuration website.

Then load your `.env` file as follows:

```matlab
loadenv(".env")
```

## Getting Started with Chat Completion API

To get started, you can either create an `openAIChat`, `azureChat`, or `ollamaChat` object and use its methods or use it in a more complex setup, as needed.

### Simple call without preserving chat history

In some situations, you will want to use chat completion models without preserving chat history. For example, when you want to perform independent queries in a programmatic way.

Here's a simple example of how to use the `openAIChat` for sentiment analysis:

```matlab
% Initialize the OpenAI Chat object, passing a system prompt

% The system prompt tells the assistant how to behave, in this case, as a sentiment analyzer
systemPrompt = "You are a sentiment analyser. You will look at a sentence and output"+...
    " a single word that classifies that sentence as either 'positive' or 'negative'."+....
    newline + ...
    "Examples:" + newline +...
    "The project was a complete failure." + newline +...
    "negative" + newline + newline +...  
    "The team successfully completed the project ahead of schedule." + newline +...
    "positive" + newline + newline +...
    "His attitude was terribly discouraging to the team." + newline +...
    "negative" + newline + newline;

chat = openAIChat(systemPrompt);

% Generate a response, passing a new sentence for classification
txt = generate(chat,"The team is feeling very motivated")
% Should output "positive"
```

### Creating a chat system

If you want to create a chat system, you will have to create a history of the conversation and pass that to the `generate` function.

To start a conversation history, create a `openAIMessages` object:

```matlab
history = openAIMessages;
```

Then create the chat assistant:

```matlab
chat = openAIChat("You are a helpful AI assistant.");
```

(Side note: `azureChat` and `ollamaChat` work with `openAIMessages`, too.)

Add a user message to the history and pass it to `generate`:

```matlab
history = addUserMessage(history,"What is an eigenvalue?");
[txt, response] = generate(chat, history)
```

The output `txt` will contain the answer and `response` will contain the full response, which you need to include in the history as follows:
```matlab
history = addResponseMessage(history, response);
```

You can keep interacting with the API and since we are saving the history, it will know about previous interactions.
```matlab
history = addUserMessage(history,"Generate MATLAB code that computes that");
[txt, response] = generate(chat,history);
% Will generate code to compute the eigenvalue
```

### Streaming the response

Streaming allows you to start receiving the output from the API as it is generated token by token, rather than wait for the entire completion to be generated. You can specifying the streaming function when you create the chat assistant. In this example, the streaming function will print the response to the command window.
```matlab
% streaming function
sf = @(x)fprintf("%s",x);
chat = openAIChat(StreamFun=sf);
txt = generate(chat,"What is Model-Based Design and how is it related to Digital Twin?")
% Should stream the response token by token
```

### Calling MATLAB functions with the API

(This is currently not supported for `ollamaChat`.)

Optionally, `Tools=functions` can be used to provide function specifications to the API. The purpose of this is to enable models to generate function arguments which adhere to the provided specifications. 
Note that the API is not able to directly call any function, so you should call the function and pass the values to the API directly. This process can be automated as shown in [AnalyzeScientificPapersUsingFunctionCalls.mlx](/examples/AnalyzeScientificPapersUsingFunctionCalls.mlx), but it's important to consider that ChatGPT can hallucinate function names, so avoid executing any arbitrary generated functions and only allow the execution of functions that you have defined. 

For example, if you want to use the API for mathematical operations such as `sind`, instead of letting the model generate the result and risk running into hallucinations, you can give the model direct access to the function as follows:


```matlab
f = openAIFunction("sind","Sine of argument in degrees");
f = addParameter(f,"x",type="number",description="Angle in degrees.");
chat = openAIChat("You are a helpful assistant.",Tools=f);
```

When the model identifies that it could use the defined functions to answer a query, it will return a `tool_calls` request, instead of directly generating the response:

```matlab
messages = openAIMessages;
messages = addUserMessage(messages, "What is the sine of 30?");
[txt, response] = generate(chat, messages);
messages = addResponseMessage(messages, response);
```

The variable `response` should contain a request for a function call.
```bash
>> response

response = 

  struct with fields:

             role: 'assistant'
          content: []
       tool_calls: [1×1 struct]

>> response.tool_calls

ans = 

  struct with fields:

           id: 'call_wDpCLqtLhXiuRpKFw71gXzdy'
         type: 'function'
     function: [1×1 struct]

>> response.tool_calls.function

ans = 

  struct with fields:

         name: 'sind'
    arguments: '{↵  "x": 30↵}'
```

You can then call the function `sind` with the specified argument and return the value to the API add a function message to the history:

```matlab
% Arguments are returned as json, so you need to decode it first
id = string(response.tool_calls.id);
func = string(response.tool_calls.function.name);
if func == "sind"
    args = jsondecode(response.tool_calls.function.arguments);
    result = sind(args.x);
    messages = addToolMessage(messages,id,func,"x="+result);
    [txt, response] = generate(chat, messages);
else
    % handle calls to unknown functions
end
```

The model then will use the function result to generate a more precise response:

```shell
>> txt

txt = 

    "The sine of 30 degrees is approximately 0.5."
```

### Extracting structured information with the API

Another useful application for defining functions is extract structured information from some text. You can just pass a function with the output format that you would like the model to output and the information you want to extract. For example, consider the following piece of text:

```matlab
patientReport = "Patient John Doe, a 45-year-old male, presented " + ...
    "with a two-week history of persistent cough and fatigue. " + ...
    "Chest X-ray revealed an abnormal shadow in the right lung." + ...
    " A CT scan confirmed a 3cm mass in the right upper lobe," + ...
    " suggestive of lung cancer. The patient has been referred " + ...
    "for biopsy to confirm the diagnosis.";
```

If you want to extract information from this text, you can define a function as follows:
```matlab
f = openAIFunction("extractPatientData","Extracts data about a patient from a record");
f = addParameter(f,"patientName",type="string",description="Name of the patient");
f = addParameter(f,"patientAge",type="number",description="Age of the patient");
f = addParameter(f,"patientSymptoms",type="string",description="Symptoms that the patient is having.");
```

Note that this function does not need to exist, since it will only be used to extract the Name, Age and Symptoms of the patient and it does not need to be called:

```matlab
chat = openAIChat("You are helpful assistant that reads patient records and extracts information", ...
    Tools=f);
messages = openAIMessages;
messages = addUserMessage(messages,"Extract the information from the report:" + newline + patientReport);
[txt, response] = generate(chat, messages);
```

The model should return the extracted information as a function call:
```shell
>> response

response = 

  struct with fields:

             role: 'assistant'
          content: []
        tool_call: [1×1 struct]

>> response.tool_calls

ans = 

  struct with fields:

           id: 'call_4VRtN7jb3pTPosMSb4ZaLoWP'
         type: 'function'
     function: [1×1 struct]

>> response.tool_calls.function

ans = 

  struct with fields:

         name: 'extractPatientData'
    arguments: '{↵  "patientName": "John Doe",↵  "patientAge": 45,↵  "patientSymptoms": "persistent cough, fatigue"↵}'
```

You can extract the arguments and write the data to a table, for example.

### Understand the content of an image

You can use gpt-4-turbo to experiment with image understanding. 
```matlab
chat = openAIChat("You are an AI assistant.", ModelName="gpt-4-turbo");
image_path = "peppers.png";
messages = openAIMessages;
messages = addUserMessageWithImages(messages,"What is in the image?",image_path);
[txt,response] = generate(chat,messages,MaxNumTokens=4096);
% Should output the description of the image
```

## Establishing a connection to Chat Completions API using Azure

If you would like to connect MATLAB to Chat Completions API via Azure instead of directly with OpenAI, you will have to create an `azureChat` object. See [the Azure documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/chatgpt-quickstart) for details on the setup required and where to find your key, endpoint, and deployment name. As explained above, the key should be in the environment variable `AZURE_OPENAI_API_KEY`, or provided as `APIKey=…` in the `azureChat` call below.

In order to create the chat assistant, you must specify your Azure OpenAI Resource and the LLM you want to use:
```matlab
chat = azureChat(YOUR_ENDPOINT_NAME, YOUR_DEPLOYMENT_NAME, "You are a helpful AI assistant");
```

The `azureChat` object also allows to specify additional options in the same way as the `openAIChat` object.
However, the `ModelName` option is not available due to the fact that the name of the LLM is already specified when creating the chat assistant.

On the other hand, the `azureChat` object offers an additional option that allows you to set the API version that you want to use for the operation.

After establishing your connection with Azure, you can continue using the `generate` function and other objects in the same way as if you had established a connection directly with OpenAI:
```matlab
% Initialize the Azure Chat object, passing a system prompt and specifying the API version
chat = azureChat(YOUR_RESOURCE_NAME, YOUR_DEPLOYMENT_NAME, "You are a helpful AI assistant", APIVersion="2023-12-01-preview");

% Create an openAIMessages object to start the conversation history
history = openAIMessages;

% Ask your question and store it in the history, create the response using the generate method, and store the response in the history 
history = addUserMessage(history,"What is an eigenvalue?");
[txt, response] = generate(chat, history)
history = addResponseMessage(history, response);
```

## Establishing a connection to local LLMs using Ollama

In case you want to use a local LLM (e.g., to avoid sending sensitive data to a cloud provider, or to use other models), you will need to install Ollama and pull a model, following the instructions on [ollama.com](https://ollama.com). Ollama needs to run on the same machine as your MATLAB instance.

In order to create the chat assistant, you must specify the LLM you want to use:
```matlab
chat = ollamaChat("mistral");
```

The additional options of `ollamaChat` are similar to those of `openAIChat` and `azureChat`.

In many workflows, `ollamaChat` is drop-in compatible with `openAIChat`:
```matlab
% Initialize the chat object
chat = ollamaChat("phi3");

% Create an openAIMessages object to start the conversation history
history = openAIMessages;

% Ask your question and store it in the history, create the response using the generate method, and store the response in the history 
history = addUserMessage(history,"What is an eigenvalue?");
[txt, response] = generate(chat, history)
history = addResponseMessage(history, response);
```

## Obtaining embeddings

You can extract embeddings from your text with OpenAI using the function `extractOpenAIEmbeddings` as follows:
```matlab
exampleText = "Here is an example!";
emb = extractOpenAIEmbeddings(exampleText);
```

The resulting embedding is a vector that captures the semantics of your text and can be used on tasks such as retrieval augmented generation and clustering.

```matlab
>> size(emb)

ans =

           1        1536
```
## Getting Started with Images API

To get started, you can either create an `openAIImages` object and use its methods or use it in a more complex setup, as needed.

```matlab
mdl = openAIImages(ModelName="dall-e-3");
images = generate(mdl,"Create a 3D avatar of a whimsical sushi on the beach. He is decorated with various sushi elements and is playfully interacting with the beach environment.");
figure
imshow(images{1})
% Should output an image based on the prompt
```

## Examples
To learn how to use this in your workflows, see [Examples](/examples/).

- [ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.mlx](/examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.mlx): Learn to implement a simple chat that stream the response. 
- [SummarizeLargeDocumentsUsingChatGPTandMATLAB.mlx](/examples/SummarizeLargeDocumentsUsingChatGPTandMATLAB.mlx): Learn to create concise summaries of long texts with ChatGPT. (Requires Text Analytics Toolbox™)
- [CreateSimpleChatBot.mlx](/examples/CreateSimpleChatBot.mlx): Build a conversational chatbot capable of handling various dialogue scenarios using ChatGPT. (Requires Text Analytics Toolbox)
- [AnalyzeScientificPapersUsingFunctionCalls.mlx](/examples/AnalyzeScientificPapersUsingFunctionCalls.mlx): Learn how to create agents capable of executing MATLAB functions. 
- [AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.mlx](/examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.mlx): Learn how to take advantage of parallel function calling. 
- [RetrievalAugmentedGenerationUsingChatGPTandMATLAB.mlx](/examples/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.mlx): Learn about retrieval augmented generation with a simple use case. (Requires Text Analytics Toolbox™)
- [DescribeImagesUsingChatGPT.mlx](/examples/DescribeImagesUsingChatGPT.mlx): Learn how to use GPT-4 Turbo with Vision to understand the content of an image. 
- [AnalyzeSentimentinTextUsingChatGPTinJSONMode.mlx](/examples/AnalyzeSentimentinTextUsingChatGPTinJSONMode.mlx): Learn how to use JSON mode in chat completions
- [UsingDALLEToEditImages.mlx](/examples/UsingDALLEToEditImages.mlx): Learn how to generate images
- [UsingDALLEToGenerateImages.mlx](/examples/UsingDALLEToGenerateImages.mlx): Create variations of images and editimages. 

## License

The license is available in the license.txt file in this GitHub repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023-2024 The MathWorks, Inc.
