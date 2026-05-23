#!/bin/bash

echo "============================================================"
echo "Git Clone All Agent Projects"
echo "============================================================"
echo ""

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not inside a git repository"
    exit 1
fi

TARGET_ROOT=$(dirname "$GIT_ROOT")
echo "Target directory: $TARGET_ROOT"
echo ""

show_usage() {
    echo "Usage: $0 [module]"
    echo ""
    echo "Available modules:"
    echo "  1   - General Agent Frameworks"
    echo "  2   - Coding Agents"
    echo "  3   - Browser / Computer Control Agents"
    echo "  4   - Research Agents"
    echo "  5   - Tools / Infrastructure"
    echo "  6   - Inference Engines"
    echo "  7   - Spring Alibaba Ecosystem"
    echo "  all - Clone all modules"
    echo ""
}

if [ -z "$1" ]; then
    show_usage
    read -p "Enter module number (1-7, all): " choice
else
    choice="$1"
fi

module1() {
    echo "--- General Agent Frameworks ---"
    git clone https://github.com/langchain-ai/langchain.git "$TARGET_ROOT/langchain"
    git clone https://github.com/langchain-ai/langgraph.git "$TARGET_ROOT/langgraph"
    git clone https://github.com/openclaw/openclaw.git "$TARGET_ROOT/openclaw"
    git clone https://github.com/NousResearch/hermes-agent.git "$TARGET_ROOT/hermes-agent"
    git clone https://github.com/cloudwego/eino.git "$TARGET_ROOT/eino"
    git clone https://github.com/spring-projects/spring-ai.git "$TARGET_ROOT/spring-ai"
    git clone https://github.com/liuup/claude-code-analysis.git "$TARGET_ROOT/claude-code-analysis"
    git clone https://github.com/crewAIInc/crewAI.git "$TARGET_ROOT/crewAI"
    git clone https://github.com/ag2ai/ag2.git "$TARGET_ROOT/ag2"
    git clone https://github.com/microsoft/semantic-kernel.git "$TARGET_ROOT/semantic-kernel"
    git clone https://github.com/666ghj/BettaFish.git "$TARGET_ROOT/BettaFish"
    git clone https://github.com/666ghj/MiroFish.git "$TARGET_ROOT/MiroFish"
}

module2() {
    echo "--- Coding Agents ---"
    git clone https://github.com/bytedance/trae-agent.git "$TARGET_ROOT/trae-agent"
    git clone https://github.com/All-Hands-AI/OpenHands.git "$TARGET_ROOT/OpenHands"
    git clone https://github.com/princeton-nlp/SWE-agent.git "$TARGET_ROOT/SWE-agent"
    git clone https://github.com/paul-gauthier/aider.git "$TARGET_ROOT/aider"
    git clone https://github.com/cline/cline.git "$TARGET_ROOT/cline"
    git clone https://github.com/continuedev/continue.git "$TARGET_ROOT/continue"
    git clone https://github.com/anomalyco/opencode.git "$TARGET_ROOT/opencode"
    git clone https://github.com/earendil-works/pi.git "$TARGET_ROOT/pi"
}

module3() {
    echo "--- Browser / Computer Control Agents ---"
    git clone https://github.com/browser-use/browser-use.git "$TARGET_ROOT/browser-use"
    git clone https://github.com/anthropics/anthropic-quickstarts.git "$TARGET_ROOT/anthropic-quickstarts"
}

module4() {
    echo "--- Research Agents ---"
    git clone https://github.com/assafelovic/gpt-researcher.git "$TARGET_ROOT/gpt-researcher"
}

module5() {
    echo "--- Tools / Infrastructure ---"
    git clone https://github.com/modelcontextprotocol/servers.git "$TARGET_ROOT/mcp-servers"
    git clone https://github.com/modelcontextprotocol/python-sdk.git "$TARGET_ROOT/mcp-python-sdk"
    git clone https://github.com/modelcontextprotocol/typescript-sdk.git "$TARGET_ROOT/mcp-typescript-sdk"
}

module6() {
    echo "--- Inference Engines ---"
    git clone https://github.com/vllm-project/vllm.git "$TARGET_ROOT/vllm"
}

module7() {
    echo "--- Spring Alibaba Ecosystem ---"
    git clone https://github.com/alibaba/spring-ai-alibaba.git "$TARGET_ROOT/spring-ai-alibaba"
    git clone https://github.com/spring-ai-alibaba/examples.git "$TARGET_ROOT/spring-ai-alibaba-examples"
    git clone https://github.com/alibaba/assistant-agent.git "$TARGET_ROOT/assistant-agent"
    git clone https://github.com/spring-ai-alibaba/deepresearch.git "$TARGET_ROOT/deepresearch"
    git clone https://github.com/spring-ai-alibaba/jmanus.git "$TARGET_ROOT/jmanus"
    git clone https://github.com/spring-ai-alibaba/dataagent.git "$TARGET_ROOT/dataagent"
}

all_modules() {
    module1
    echo ""
    module2
    echo ""
    module3
    echo ""
    module4
    echo ""
    module5
    echo ""
    module6
    echo ""
    module7
}

case "$choice" in
    1) module1 ;;
    2) module2 ;;
    3) module3 ;;
    4) module4 ;;
    5) module5 ;;
    6) module6 ;;
    7) module7 ;;
    all) all_modules ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "============================================================"
echo "Done!"
echo "============================================================"
