classdef tazureChat < matlab.unittest.TestCase
% Tests for azureChat

%   Copyright 2024 The MathWorks, Inc.

    properties(TestParameter)
        InvalidConstructorInput = iGetInvalidConstructorInput;
        InvalidGenerateInput = iGetInvalidGenerateInput;
        InvalidValuesSetters = iGetInvalidValuesSetters;
        StringInputs = struct('string',{"hi"},'char',{'hi'},'cellstr',{{'hi'}});
        APIVersions = iGetAPIVersions();
    end

    methods(Test)
        function constructChatWithAllNVP(testCase)
            deploymentID = "hello";
            functions = openAIFunction("funName");
            temperature = 0;
            topP = 1;
            stop = ["[END]", "."];
            apiKey = "this-is-not-a-real-key";
            presenceP = -2;
            frequenceP = 2;
            systemPrompt = "This is a system prompt";
            timeout = 3;
            chat = azureChat(systemPrompt, Deployment=deploymentID, Tools=functions, ...
                Temperature=temperature, TopP=topP, StopSequences=stop, APIKey=apiKey,...
                FrequencyPenalty=frequenceP, PresencePenalty=presenceP, TimeOut=timeout);
            testCase.verifyEqual(chat.Temperature, temperature);
            testCase.verifyEqual(chat.TopP, topP);
            testCase.verifyEqual(chat.StopSequences, stop);
            testCase.verifyEqual(chat.FrequencyPenalty, frequenceP);
            testCase.verifyEqual(chat.PresencePenalty, presenceP);
        end

        function doGenerate(testCase,StringInputs)
            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            chat = azureChat;
            response = testCase.verifyWarningFree(@() generate(chat,StringInputs));
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);
        end

        function generateMultipleResponses(testCase)
            chat = azureChat;
            [~,~,response] = generate(chat,"What is a cat?",NumCompletions=3);
            testCase.verifySize(response.Body.Data.choices,[3,1]);
        end


        function doReturnErrors(testCase)
            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            chat = azureChat;
            % This input is considerably longer than accepted as input for
            % GPT-3.5 (16385 tokens)
            wayTooLong = string(repmat('a ',1,20000));
            testCase.verifyError(@() generate(chat,wayTooLong), "llms:apiReturnedError");
        end

        function seedFixesResult(testCase)
            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            chat = azureChat;
            response1 = generate(chat,"hi",Seed=1234);
            response2 = generate(chat,"hi",Seed=1234);
            testCase.verifyEqual(response1,response2);
        end

        function createAzureChatWithStreamFunc(testCase)
            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            function seen = sf(str)
                persistent data;
                if isempty(data)
                    data = strings(1, 0);
                end
                % Append streamed text to an empty string array of length 1
                data = [data, str];
                seen = data;
            end
            chat = azureChat(StreamFun=@sf);

            testCase.verifyWarningFree(@()generate(chat, "Hello world."));
            % Checking that persistent data, which is still stored in
            % memory, is greater than 1. This would mean that the stream
            % function has been called and streamed some text.
            testCase.verifyGreaterThan(numel(sf("")), 1);
        end

        function generateWithTools(testCase)
            import matlab.unittest.constraints.HasField

            f = openAIFunction("getCurrentWeather", "Get the current weather in a given location");
            f = addParameter(f, "location", type="string", description="The city and country, optionally state. E.g., San Francisco, CA, USA");
            f = addParameter(f, "unit", type="string", enum=["Kelvin","Celsius"], RequiredParameter=false);

            chat = azureChat(Tools=f);

            prompt =  "What's the weather like in San Francisco, Tokyo, and Paris?";
            [~, response] = generate(chat, prompt, ToolChoice="getCurrentWeather");

            testCase.assertThat(response, HasField("tool_calls"));
            testCase.assertEqual(response.tool_calls.type,'function');
            testCase.assertEqual(response.tool_calls.function.name,'getCurrentWeather');
            data = testCase.verifyWarningFree( ...
                @() jsondecode(response.tool_calls.function.arguments));
            testCase.verifyThat(data,HasField("location"));
        end

        function errorsWhenPassingToolChoiceWithEmptyTools(testCase)
            chat = azureChat(APIKey="this-is-not-a-real-key");
            testCase.verifyError(@()generate(chat,"input", ToolChoice="bla"), "llms:mustSetFunctionsForCall");
        end

        function shortErrorForBadEndpoint(testCase)
            chat = azureChat(Endpoint="https://nobodyhere.whatever/");
            caught = false;
            try
                generate(chat,"input");
            catch ME
                caught = ME;
            end
            testCase.assertClass(caught,"MException");
            testCase.verifyEqual(caught.identifier,'MATLAB:webservices:UnknownHost');
            testCase.verifyEmpty(caught.cause);
        end

        function invalidInputsConstructor(testCase, InvalidConstructorInput)
            testCase.verifyError(@()azureChat(InvalidConstructorInput.Input{:}), InvalidConstructorInput.Error);
        end

        function invalidInputsGenerate(testCase, InvalidGenerateInput)
            f = openAIFunction("validfunction");
            chat = azureChat(Tools=f, APIKey="this-is-not-a-real-key");
            testCase.verifyError(@()generate(chat,InvalidGenerateInput.Input{:}), InvalidGenerateInput.Error);
        end

        function invalidSetters(testCase, InvalidValuesSetters)
            chat = azureChat(APIKey="this-is-not-a-real-key");
            function assignValueToProperty(property, value)
                chat.(property) = value;
            end

            testCase.verifyError(@()assignValueToProperty(InvalidValuesSetters.Property,InvalidValuesSetters.Value), InvalidValuesSetters.Error);
        end

        function keyNotFound(testCase)
            % to verify the error, we need to unset the environment variable
            % AZURE_OPENAI_API_KEY, if given. Use a fixture to restore the
            % value on leaving the test point:
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("AZURE_OPENAI_API_KEY","dummy"));
            unsetenv("AZURE_OPENAI_API_KEY");
            testCase.verifyError(@()azureChat, "llms:keyMustBeSpecified");
        end

        function canUseAPIVersions(testCase, APIVersions)
            % Test that we can use different APIVersion value to call 
            % azureChat.generate

            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            chat = azureChat("APIVersion", APIVersions);

            response = testCase.verifyWarningFree(@() generate(chat,"How similar is the DNA of a cat and a tiger?"));
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);

        end
    end
end

function invalidValuesSetters = iGetInvalidValuesSetters

invalidValuesSetters = struct( ...
    "InvalidTemperatureType", struct( ...
        "Property", "Temperature", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidTemperatureSize", struct( ...
        "Property", "Temperature", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "TemperatureTooLarge", struct( ...
        "Property", "Temperature", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "TemperatureTooSmall", struct( ...
        "Property", "Temperature", ...
        "Value", -20, ...
        "Error", "MATLAB:expectedNonnegative"), ...
    ...
    "InvalidTopPType", struct( ...
        "Property", "TopP", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidTopPSize", struct( ...
        "Property", "TopP", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "TopPTooLarge", struct( ...
        "Property", "TopP", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "TopPTooSmall", struct( ...
        "Property", "TopP", ...
        "Value", -20, ...
        "Error", "MATLAB:expectedNonnegative"), ...
    ...
    "WrongTypeStopSequences", struct( ...
        "Property", "StopSequences", ...
        "Value", 123, ...
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
    ...
    "WrongSizeStopNonVector", struct( ...
        "Property", "StopSequences", ...
        "Value", repmat("stop", 4), ...
        "Error", "MATLAB:validators:mustBeVector"), ...
    ...
    "EmptyStopSequences", struct( ...
        "Property", "StopSequences", ...
        "Value", "", ...
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
    ...
    "WrongSizeStopSequences", struct( ...
        "Property", "StopSequences", ...
        "Value", ["1" "2" "3" "4" "5"], ...
        "Error", "llms:stopSequencesMustHaveMax4Elements"), ...
    ...
    "InvalidPresencePenalty", struct( ...
        "Property", "PresencePenalty", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidPresencePenaltySize", struct( ...
        "Property", "PresencePenalty", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "PresencePenaltyTooLarge", struct( ...
        "Property", "PresencePenalty", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "PresencePenaltyTooSmall", struct( ...
        "Property", "PresencePenalty", ...
        "Value", -20, ...
        "Error", "MATLAB:notGreaterEqual"), ...
    ...
    "InvalidFrequencyPenalty", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidFrequencyPenaltySize", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "FrequencyPenaltyTooLarge", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "FrequencyPenaltyTooSmall", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", -20, ...
        "Error", "MATLAB:notGreaterEqual"));
end

function invalidConstructorInput = iGetInvalidConstructorInput
validFunction = openAIFunction("funName");
invalidConstructorInput = struct( ...
    "InvalidResponseFormatValue", struct( ...
        "Input",{{"ResponseFormat", "foo" }},...
        "Error", "MATLAB:validators:mustBeMember"), ...
    ...
    "InvalidResponseFormatSize", struct( ...
        "Input",{{"ResponseFormat", ["text" "text"] }},...
        "Error", "MATLAB:validation:IncompatibleSize"), ...
    ...
    "InvalidStreamFunType", struct( ...
        "Input",{{"StreamFun", "2" }},...
        "Error", "MATLAB:validators:mustBeA"), ...
    ...
    "InvalidStreamFunSize", struct( ...
        "Input",{{"StreamFun", [1 1 1] }},...
        "Error", "MATLAB:validation:IncompatibleSize"), ...
    ...
    "InvalidTimeOutType", struct( ...
        "Input",{{"TimeOut", "2" }},...
        "Error", "MATLAB:validators:mustBeReal"), ...
    ...
    "InvalidTimeOutSize", struct( ...
        "Input",{{"TimeOut", [1 1 1] }},...
        "Error", "MATLAB:validation:IncompatibleSize"), ...
    ...
    "WrongTypeSystemPrompt",struct( ...
        "Input",{{ 123 }},...
        "Error","MATLAB:validators:mustBeTextScalar"),...
    ...
    "WrongSizeSystemPrompt",struct( ...
        "Input",{{ ["test"; "test"] }},...
        "Error","MATLAB:validators:mustBeTextScalar"),...
    ...
    "InvalidToolsType",struct( ...
        "Input",{{"Tools", "a" }},...
        "Error","MATLAB:validators:mustBeA"),...
    ...
    "InvalidToolsSize",struct( ...
        "Input",{{"Tools", repmat(validFunction, 2, 2) }},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidAPIVersionType",struct( ...
        "Input",{{"APIVersion", 0}},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidAPIVersionSize",struct( ...
        "Input",{{"APIVersion", ["2023-05-15", "2023-05-15"]}},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidAPIVersionOption",struct( ...
        "Input",{{ "APIVersion", "gpt" }},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidTemperatureType",struct( ...
        "Input",{{ "Temperature" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidTemperatureSize",struct( ...
        "Input",{{ "Temperature" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "TemperatureTooLarge",struct( ...
        "Input",{{ "Temperature" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "TemperatureTooSmall",struct( ...
        "Input",{{ "Temperature" -20 }},...
        "Error","MATLAB:expectedNonnegative"),...
    ...
    "InvalidTopPType",struct( ...
        "Input",{{  "TopP" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidTopPSize",struct( ...
        "Input",{{  "TopP" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "TopPTooLarge",struct( ...
        "Input",{{  "TopP" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "TopPTooSmall",struct( ...
        "Input",{{ "TopP" -20 }},...
        "Error","MATLAB:expectedNonnegative"),...
    ...
    "WrongTypeStopSequences",struct( ...
        "Input",{{ "StopSequences" 123}},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "WrongSizeStopNonVector",struct( ...
        "Input",{{ "StopSequences" repmat("stop", 4) }},...
        "Error","MATLAB:validators:mustBeVector"),...
    ...
    "EmptyStopSequences",struct( ...
        "Input",{{ "StopSequences" ""}},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "WrongSizeStopSequences",struct( ...
        "Input",{{ "StopSequences" ["1" "2" "3" "4" "5"]}},...
        "Error","llms:stopSequencesMustHaveMax4Elements"),...
    ...
    "InvalidPresencePenalty",struct( ...
        "Input",{{ "PresencePenalty" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidPresencePenaltySize",struct( ...
        "Input",{{ "PresencePenalty" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "PresencePenaltyTooLarge",struct( ...
        "Input",{{ "PresencePenalty" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "PresencePenaltyTooSmall",struct( ...
        "Input",{{ "PresencePenalty" -20 }},...
        "Error","MATLAB:notGreaterEqual"),...
    ...
    "InvalidFrequencyPenalty",struct( ...
        "Input",{{ "FrequencyPenalty" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidFrequencyPenaltySize",struct( ...
        "Input",{{ "FrequencyPenalty" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "FrequencyPenaltyTooLarge",struct( ...
        "Input",{{ "FrequencyPenalty" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "FrequencyPenaltyTooSmall",struct( ...
        "Input",{{ "FrequencyPenalty" -20 }},...
        "Error","MATLAB:notGreaterEqual"),...
    ...
    "InvalidApiKeyType",struct( ...
        "Input",{{ "APIKey" 123 }},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "InvalidApiKeySize",struct( ...
        "Input",{{ "APIKey" ["abc" "abc"] }},...
        "Error","MATLAB:validators:mustBeTextScalar"));
end

function invalidGenerateInput = iGetInvalidGenerateInput
emptyMessages = messageHistory;
validMessages = addUserMessage(emptyMessages,"Who invented the telephone?");

invalidGenerateInput = struct( ...
        "EmptyInput",struct( ...
            "Input",{{ [] }},...
            "Error","llms:mustBeMessagesOrTxt"),...
        ...
        "InvalidInputType",struct( ...
            "Input",{{ 123 }},...
            "Error","llms:mustBeMessagesOrTxt"),...
        ...
        "EmptyMessages",struct( ...
            "Input",{{ emptyMessages }},...
            "Error","llms:mustHaveMessages"),...
        ...
        "InvalidMaxNumTokensType",struct( ...
            "Input",{{ validMessages  "MaxNumTokens" "2" }},...
            "Error","MATLAB:validators:mustBeNumericOrLogical"),...
        ...
        "InvalidMaxNumTokensValue",struct( ...
            "Input",{{ validMessages  "MaxNumTokens" 0 }},...
            "Error","MATLAB:validators:mustBePositive"),...
        ...
        "InvalidNumCompletionsType",struct( ...
            "Input",{{ validMessages  "NumCompletions" "2" }},...
            "Error","MATLAB:validators:mustBeNumericOrLogical"),...
        ...
        "InvalidNumCompletionsValue",struct( ...
            "Input",{{ validMessages  "NumCompletions" 0 }},...
            "Error","MATLAB:validators:mustBePositive"), ...
        ...
        "InvalidToolChoiceValue",struct( ...
            "Input",{{ validMessages  "ToolChoice" "functionDoesNotExist" }},...
            "Error","MATLAB:validators:mustBeMember"),...
        ...
        "InvalidToolChoiceType",struct( ...
            "Input",{{ validMessages  "ToolChoice" 0 }},...
            "Error","MATLAB:validators:mustBeTextScalar"),...
        ...
        "InvalidToolChoiceSize",struct( ...
            "Input",{{ validMessages  "ToolChoice" ["validfunction", "validfunction"] }},...
            "Error","MATLAB:validators:mustBeTextScalar"));
end

function apiVersions = iGetAPIVersions()
apiVersions = cellstr(llms.azure.apiVersions);
end