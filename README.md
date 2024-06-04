# [Analysis of results of open source LLM models](notebooks_and_scripts/for_using_models)

## Setting up the environment 

For the project to work correctly, you must install the following components:
1) [Python 3.10](https://www.python.org/downloads/release/python-3100/);
2) [CUDA Toolkit 12.4 (Version 11)](https://developer.nvidia.com/cuda-downloads?target_os=Windows&target_arch=x86_64&target_version=11&target_type=exe_network);
3) [cuDNN 9.0.0 (Version 10)](https://developer.nvidia.com/cudnn-downloads?target_os=Windows&target_arch=x86_64&target_version=10&target_type=exe_local).

[This laptop](/notebooks_and_scripts/for_using_models/setup_libs.ipynb) will help you install all the necessary libraries.

**Note**: If you need to run and test the scripts offered in this section, additional path configuration will be required. Testing was performed on Windows 10.

All models are saved along the path: `C:\Users\<user name>\.cache\huggingface\hub`

## Models to be tested

- [stabilityai/stable-code-3b](https://huggingface.co/stabilityai/stable-code-3b)
- [bigcode/octocoder](https://huggingface.co/bigcode/octocoder)
- [deepseek-ai/deepseek-coder-6.7b-instruct](https://huggingface.co/deepseek-ai/deepseek-coder-6.7b-instruct)
- [WizardLM/WizardCoder-15B-V1.0](https://huggingface.co/WizardLM/WizardCoder-15B-V1.0)
- [nextai-team / Moe-2x7b-QA-Code](https://huggingface.co/nextai-team/Moe-2x7b-QA-Code)
- [microsoft/phi-1](https://huggingface.co/microsoft/phi-1)
- [codellama/CodeLlama-13b-hf](https://huggingface.co/codellama/CodeLlama-13b-hf)
- [codellama/CodeLlama-34b-Instruct-hf](https://huggingface.co/codellama/CodeLlama-34b-Instruct-hf)

## Data collection and processing

- [This laptop](notebooks/local_run_llm.ipynb) will help you run locally and collect the model's responses to samples provided to it into a single JSON file.
- It is possible to use the API from Hugging Face. [The laptop](notebooks/hf_api_run_llm.ipynb) will help you with this task, but you will need your own [access key](https://huggingface.co/settings/tokens) in `WRITE` mode.
- You can process the collected model results using [this laptop](notebooks/check_stats.ipynb). The output will summarize the final accuracy of the model's responses. If necessary, it is possible to collect statistics on response time delay.
- The results of the answers can be found along the path `..\data\collected_generated_text`.

## Features of launching models

Due to the lack of infinite video memory, the tests had to resort to quantization of models, which made the final results not entirely reliable. The response delay will not be reflected in the results due to differences in the accelerators on which the calculations took place.

## Test results

All models performed poorly on multi-class classification, showing results of less than 5%.

The best result of binary classification was demonstrated by the stabilityai/stable-code-3b model. But it’s hard to call it a success. It seems that this model was throwing out conclusions absolutely randomly, and it is difficult to trust its results.

<img src="figures/test_results.png" width=80% />

It is noteworthy to note that all models exhibit hallucination in one manner or another. The models claim that there are no vulnerabilities in the code, but then indicate the CWE ID in the same response.


# [Collecting a dataset to train your own model](/notebooks_and_scripts/dataset_collection)

## Setting up the environment 

For the project to work correctly, you must install the Java, JDK 17.0.10 and static analyzer PVS-Studio.

**Note**: Data collection and analysis were performed on Ubuntu 20.04.6 LTS.

## Data collection and processing

- [This laptop](/notebooks_and_scripts/dataset_collection/commit_msg_analyzer/msg_analyzer.ipynb) will help you analyze existing commits in a selected GitHub repository. [The result](/notebooks_and_scripts/dataset_collection/commit_msg_analyzer/result) of [this script](/notebooks_and_scripts/dataset_collection/commit_msg_analyzer/msg_analyzer.ipynb) should be a cloned repository in the current directory and [keyword-filtered](/notebooks_and_scripts/dataset_collection/commit_msg_analyzer/keywords.csv) commits.
- Find and copy versions of collected commits [this script](/notebooks_and_scripts/dataset_collection/change_tracking/getting_all_changes.ipynb). Here you can also launch a Bash script to [run static analysis](/notebooks_and_scripts/dataset_collection/change_tracking/start_analysis.sh), taking into account the operating features of the product being used.
- [This script](/notebooks_and_scripts/dataset_collection/change_tracking/parsing_vulnerable_java_functions.ipynb) will help you parse the found vulnerabilities. When searching for a fix, the script only considers fixed vulnerabilities. Additional vulnerabilities will be missed.

## Results

Using the [elasticsearch](https://github.com/elastic/elasticsearch) repository as an example, 165 commits with vulnerability fixes were found using PVS-Studio. In total, 394 corrected scripts were collected.