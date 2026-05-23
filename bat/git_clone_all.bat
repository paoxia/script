@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo Git Clone All Agent Projects
echo ============================================================
echo.

for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "GIT_ROOT=%%i"
if not defined GIT_ROOT (
    echo Error: Not inside a git repository
    pause
    exit /b 1
)

for %%i in ("%GIT_ROOT%") do set "TARGET_ROOT=%%~dpi"
set "TARGET_ROOT=!TARGET_ROOT:~0,-1!"

echo Target directory: %TARGET_ROOT%
echo.

if "%1"=="" (
    echo Usage: %~nx0 [module]
    echo.
    echo Available modules:
    echo   1  - General Agent Frameworks
    echo   2  - Coding Agents
    echo   3  - Browser / Computer Control Agents
    echo   4  - Research Agents
    echo   5  - Tools / Infrastructure
    echo   6  - Inference Engines
    echo   7  - Spring Alibaba Ecosystem
    echo   all - Clone all modules
    echo.
    set /p choice="Enter module number (1-7, all): "
) else (
    set "choice=%1"
)

if "%choice%"=="1" goto :module1
if "%choice%"=="2" goto :module2
if "%choice%"=="3" goto :module3
if "%choice%"=="4" goto :module4
if "%choice%"=="5" goto :module5
if "%choice%"=="6" goto :module6
if "%choice%"=="7" goto :module7
if "%choice%"=="all" goto :all
echo Invalid choice!
exit /b 1

:module1
echo --- General Agent Frameworks ---
git clone https://github.com/langchain-ai/langchain.git "%TARGET_ROOT%\langchain"
git clone https://github.com/langchain-ai/langgraph.git "%TARGET_ROOT%\langgraph"
git clone https://github.com/openclaw/openclaw.git "%TARGET_ROOT%\openclaw"
git clone https://github.com/NousResearch/hermes-agent.git "%TARGET_ROOT%\hermes-agent"
git clone https://github.com/cloudwego/eino.git "%TARGET_ROOT%\eino"
git clone https://github.com/spring-projects/spring-ai.git "%TARGET_ROOT%\spring-ai"
git clone https://github.com/liuup/claude-code-analysis.git "%TARGET_ROOT%\claude-code-analysis"
git clone https://github.com/crewAIInc/crewAI.git "%TARGET_ROOT%\crewAI"
git clone https://github.com/ag2ai/ag2.git "%TARGET_ROOT%\ag2"
git clone https://github.com/microsoft/semantic-kernel.git "%TARGET_ROOT%\semantic-kernel"
git clone https://github.com/666ghj/BettaFish.git "%TARGET_ROOT%\BettaFish"
git clone https://github.com/666ghj/MiroFish.git "%TARGET_ROOT%\MiroFish"
goto :end

:module2
echo --- Coding Agents ---
git clone https://github.com/bytedance/trae-agent.git "%TARGET_ROOT%\trae-agent"
git clone https://github.com/All-Hands-AI/OpenHands.git "%TARGET_ROOT%\OpenHands"
git clone https://github.com/princeton-nlp/SWE-agent.git "%TARGET_ROOT%\SWE-agent"
git clone https://github.com/paul-gauthier/aider.git "%TARGET_ROOT%\aider"
git clone https://github.com/cline/cline.git "%TARGET_ROOT%\cline"
git clone https://github.com/continuedev/continue.git "%TARGET_ROOT%\continue"
git clone https://github.com/anomalyco/opencode.git "%TARGET_ROOT%\opencode"
git clone https://github.com/earendil-works/pi.git "%TARGET_ROOT%\pi"
goto :end

:module3
echo --- Browser / Computer Control Agents ---
git clone https://github.com/browser-use/browser-use.git "%TARGET_ROOT%\browser-use"
git clone https://github.com/anthropics/anthropic-quickstarts.git "%TARGET_ROOT%\anthropic-quickstarts"
goto :end

:module4
echo --- Research Agents ---
git clone https://github.com/assafelovic/gpt-researcher.git "%TARGET_ROOT%\gpt-researcher"
goto :end

:module5
echo --- Tools / Infrastructure ---
git clone https://github.com/modelcontextprotocol/servers.git "%TARGET_ROOT%\mcp-servers"
git clone https://github.com/modelcontextprotocol/python-sdk.git "%TARGET_ROOT%\mcp-python-sdk"
git clone https://github.com/modelcontextprotocol/typescript-sdk.git "%TARGET_ROOT%\mcp-typescript-sdk"
goto :end

:module6
echo --- Inference Engines ---
git clone https://github.com/vllm-project/vllm.git "%TARGET_ROOT%\vllm"
goto :end

:module7
echo --- Spring Alibaba Ecosystem ---
git clone https://github.com/alibaba/spring-ai-alibaba.git "%TARGET_ROOT%\spring-ai-alibaba"
git clone https://github.com/spring-ai-alibaba/examples.git "%TARGET_ROOT%\spring-ai-alibaba-examples"
git clone https://github.com/alibaba/assistant-agent.git "%TARGET_ROOT%\assistant-agent"
git clone https://github.com/spring-ai-alibaba/deepresearch.git "%TARGET_ROOT%\deepresearch"
git clone https://github.com/spring-ai-alibaba/jmanus.git "%TARGET_ROOT%\jmanus"
git clone https://github.com/spring-ai-alibaba/dataagent.git "%TARGET_ROOT%\dataagent"
goto :end

:all
echo --- General Agent Frameworks ---
git clone https://github.com/langchain-ai/langchain.git "%TARGET_ROOT%\langchain"
git clone https://github.com/langchain-ai/langgraph.git "%TARGET_ROOT%\langgraph"
git clone https://github.com/openclaw/openclaw.git "%TARGET_ROOT%\openclaw"
git clone https://github.com/NousResearch/hermes-agent.git "%TARGET_ROOT%\hermes-agent"
git clone https://github.com/cloudwego/eino.git "%TARGET_ROOT%\eino"
git clone https://github.com/spring-projects/spring-ai.git "%TARGET_ROOT%\spring-ai"
git clone https://github.com/liuup/claude-code-analysis.git "%TARGET_ROOT%\claude-code-analysis"
git clone https://github.com/crewAIInc/crewAI.git "%TARGET_ROOT%\crewAI"
git clone https://github.com/ag2ai/ag2.git "%TARGET_ROOT%\ag2"
git clone https://github.com/microsoft/semantic-kernel.git "%TARGET_ROOT%\semantic-kernel"
git clone https://github.com/666ghj/BettaFish.git "%TARGET_ROOT%\BettaFish"
git clone https://github.com/666ghj/MiroFish.git "%TARGET_ROOT%\MiroFish"

echo.
echo --- Coding Agents ---
git clone https://github.com/bytedance/trae-agent.git "%TARGET_ROOT%\trae-agent"
git clone https://github.com/All-Hands-AI/OpenHands.git "%TARGET_ROOT%\OpenHands"
git clone https://github.com/princeton-nlp/SWE-agent.git "%TARGET_ROOT%\SWE-agent"
git clone https://github.com/paul-gauthier/aider.git "%TARGET_ROOT%\aider"
git clone https://github.com/cline/cline.git "%TARGET_ROOT%\cline"
git clone https://github.com/continuedev/continue.git "%TARGET_ROOT%\continue"
git clone https://github.com/anomalyco/opencode.git "%TARGET_ROOT%\opencode"
git clone https://github.com/earendil-works/pi.git "%TARGET_ROOT%\pi"

echo.
echo --- Browser / Computer Control Agents ---
git clone https://github.com/browser-use/browser-use.git "%TARGET_ROOT%\browser-use"
git clone https://github.com/anthropics/anthropic-quickstarts.git "%TARGET_ROOT%\anthropic-quickstarts"

echo.
echo --- Research Agents ---
git clone https://github.com/assafelovic/gpt-researcher.git "%TARGET_ROOT%\gpt-researcher"

echo.
echo --- Tools / Infrastructure ---
git clone https://github.com/modelcontextprotocol/servers.git "%TARGET_ROOT%\mcp-servers"
git clone https://github.com/modelcontextprotocol/python-sdk.git "%TARGET_ROOT%\mcp-python-sdk"
git clone https://github.com/modelcontextprotocol/typescript-sdk.git "%TARGET_ROOT%\mcp-typescript-sdk"

echo.
echo --- Inference Engines ---
git clone https://github.com/vllm-project/vllm.git "%TARGET_ROOT%\vllm"

echo.
echo --- Spring Alibaba Ecosystem ---
git clone https://github.com/alibaba/spring-ai-alibaba.git "%TARGET_ROOT%\spring-ai-alibaba"
git clone https://github.com/spring-ai-alibaba/examples.git "%TARGET_ROOT%\spring-ai-alibaba-examples"
git clone https://github.com/alibaba/assistant-agent.git "%TARGET_ROOT%\assistant-agent"
git clone https://github.com/spring-ai-alibaba/deepresearch.git "%TARGET_ROOT%\deepresearch"
git clone https://github.com/spring-ai-alibaba/jmanus.git "%TARGET_ROOT%\jmanus"
git clone https://github.com/spring-ai-alibaba/dataagent.git "%TARGET_ROOT%\dataagent"
goto :end

:end
echo.
echo ============================================================
echo Done!
echo ============================================================
