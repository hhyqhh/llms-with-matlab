classdef textractOpenAIEmbeddings < matlab.unittest.TestCase
% Tests for extractOpenAIEmbeddings

%   Copyright 2023-2024 The MathWorks, Inc.

    methods (TestClassSetup)
        function saveEnvVar(testCase)
            % Ensures key is not in environment variable for tests
            openAIEnvVar = "OPENAI_API_KEY";
            if isenv(openAIEnvVar)
                key = getenv(openAIEnvVar);
                unsetenv(openAIEnvVar);
                testCase.addTeardown(@(x) setenv(openAIEnvVar, x), key);
            end
        end
    end

    properties(TestParameter)
        InvalidInput = iGetInvalidInput();
        ValidDimensionsModelCombinations = iGetValidDimensionsModelCombinations();
    end
    
    methods(Test)
        % Test methods
        function embedsDifferentStringTypes(testCase)
            testCase.verifyWarningFree(@()extractOpenAIEmbeddings("bla", ApiKey="this-is-not-a-real-key"));
            testCase.verifyWarningFree(@()extractOpenAIEmbeddings('bla', ApiKey="this-is-not-a-real-key"));
            testCase.verifyWarningFree(@()extractOpenAIEmbeddings({'bla'}, ApiKey="this-is-not-a-real-key"));
        end

        function keyNotFound(testCase)
            testCase.verifyError(@()extractOpenAIEmbeddings("bla"), "llms:keyMustBeSpecified");
        end

        function validCombinationOfModelAndDimension(testCase, ValidDimensionsModelCombinations)
            testCase.verifyWarningFree(@()extractOpenAIEmbeddings("bla", ...
                Dimensions=ValidDimensionsModelCombinations.Dimensions,...
                ModelName=ValidDimensionsModelCombinations.ModelName, ...
                ApiKey="not-real"));
        end

        function embedStringWithSuccessfulOpenAICall(testCase)
            testCase.verifyWarningFree(@()extractOpenAIEmbeddings("bla", ...
                ApiKey=getenv("OPENAI_KEY")));
        end

        function invalidCombinationOfModelAndDimension(testCase)
            testCase.verifyError(@()extractOpenAIEmbeddings("bla", ...
                Dimensions=10,...
                ModelName="text-embedding-ada-002", ...
                ApiKey="not-real"), ...
                "llms:invalidOptionForModel")
        end

        function useAllNVP(testCase)
            testCase.verifyWarningFree(@()extractOpenAIEmbeddings("bla", ModelName="text-embedding-ada-002", ...
                ApiKey="this-is-not-a-real-key", TimeOut=10));
        end

        %% Test is currently unreliable, reasons unclear
        % function verySmallTimeOutErrors(testCase)
        %     testCase.verifyError(@()extractOpenAIEmbeddings("bla", TimeOut=0.0001, ApiKey="false-key"), "MATLAB:webservices:Timeout")
        % end

        function testInvalidInputs(testCase, InvalidInput)
            testCase.verifyError(@()extractOpenAIEmbeddings(InvalidInput.Input{:}), InvalidInput.Error);
        end
    end    
end

function invalidInput = iGetInvalidInput()
invalidInput = struct( ...
    "InvalidEmptyText", struct( ...
        "Input",{{ "" }},...
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
    ...
    "InvalidEmptyTextArray", struct( ...
        "Input",{{ ["", ""] }},...
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
    ...
    "InvalidTimeOutType", struct( ...
        "Input",{{ "bla", "TimeOut", "2" }},...
        "Error", "MATLAB:validators:mustBeReal"), ...
    ...
    "InvalidTimeOutSize", struct( ...
        "Input",{{ "bla", "TimeOut", [1 1 1] }},...
        "Error", "MATLAB:validation:IncompatibleSize"), ...
    ...
    "WrongTypeText",struct( ...
        "Input",{{ 123 }},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "InvalidModelNameType",struct( ...
        "Input",{{"bla", "ModelName", 0 }},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidModelNameSize",struct( ...
        "Input",{{"bla", "ModelName", ["gpt-3.5-turbo",  "gpt-3.5-turbo"] }},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidModelNameOption",struct( ...
        "Input",{{"bla", "ModelName", "gpt" }},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidDimensionType",struct( ...
        "Input",{{"bla", "Dimensions", "123" }},...
        "Error","MATLAB:validators:mustBeNumericOrLogical"),...
    ...
    "InvalidDimensionValue",struct( ...
        "Input",{{"bla", "Dimensions", "-11" }},...
        "Error","MATLAB:validators:mustBeNumericOrLogical"),...
    ...
    "LargeDimensionValueForModelLarge",struct( ...
        "Input",{{"bla", "ModelName", "text-embedding-3-large", ...
            "Dimensions", 3073, "ApiKey", "fake-key"  }},...
        "Error","llms:dimensionsMustBeSmallerThan"),...
    ...
    "LargeDimensionValueForModelSmall",struct( ...
        "Input",{{"bla", "ModelName", "text-embedding-3-small", ...
            "Dimensions", 1537, "ApiKey", "fake-key" }},...
        "Error","llms:dimensionsMustBeSmallerThan"),...
    ...
    "InvalidDimensionSize",struct( ...
        "Input",{{"bla", "Dimensions", [123, 123] }},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidApiKeyType",struct( ...
        "Input",{{"bla", "ApiKey" 123 }},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "InvalidApiKeySize",struct( ...
        "Input",{{"bla", "ApiKey" ["abc" "abc"] }},...
        "Error","MATLAB:validators:mustBeTextScalar"));
end

function validDimensionsModelCombinations = iGetValidDimensionsModelCombinations()
validDimensionsModelCombinations = struct( ...
    "CaseTextEmbedding3Small", struct( ...
        "Dimensions",10,...
        "ModelName", "text-embedding-3-small"), ...
    ...
    "CaseTextEmbedding3Large", struct( ...
        "Dimensions",10,...
        "ModelName", "text-embedding-3-large"));
end
