#!/bin/bash

SYSTEM_PROMPT="You are ChatGPT, a large language model trained by OpenAI. Answer as concisely as possible. Current date: $(date +%m/%d/%Y). Knowledge cutoff: 9/1/2021."
OPENAI_KEY=pk-this-is-a-real-free-pool-token-for-everyone

request_to_chat() {
	local message="$1"
	escaped_system_prompt=$(escape "$SYSTEM_PROMPT")

	curl https://ai.fakeopen.com/v1/chat/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-H "Authorization: Bearer $OPENAI_KEY" \
		-d '{
            "model": "'"$MODEL"'",
            "messages": [
                {"role": "system", "content": "'"$escaped_system_prompt"'"},
                '"$message"'
                ],
            "max_tokens": '$MAX_TOKENS',
            "temperature": '$TEMPERATURE'
            }'
}

escape() {
	echo "$1" | jq -Rrs 'tojson[1:-1]'
}

build_user_chat_message() {
	local escaped_request_prompt="$1"
	if [ -z "$chat_message" ]; then
		chat_message="{\"role\": \"user\", \"content\": \"$escaped_request_prompt\"}"
	else
		chat_message="$chat_message, {\"role\": \"user\", \"content\": \"$escaped_request_prompt\"}"
	fi
}

add_assistant_response_to_chat_message() {
	local escaped_response_data="$1"
	chat_message="$chat_message, {\"role\": \"assistant\", \"content\": \"$escaped_response_data\"}"
}

TEMPERATURE=${TEMPERATURE:-0.7}
MAX_TOKENS=${MAX_TOKENS:-4000}
MODEL=${MODEL:-gpt-3.5-turbo}

running=true

while $running; do
	echo -e "\nEnter a prompt:"
	read -e prompt

	if [[ $prompt =~ ^(exit|q)$ ]]; then
		running=false
	else
		request_prompt=$(escape "$prompt")
		build_user_chat_message "$request_prompt"
		response=$(request_to_chat "$chat_message")
		response_data=$(echo "$response" | jq -r '.choices[].message.content')
		echo -e "${response_data}"
		add_assistant_response_to_chat_message "$(escape "$response_data")"
	fi
done
