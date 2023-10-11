#!/bin/bash

# Input JSON file containing prompts and difficulty levels
input_file="prompt/10-prompt.json"

# Output JSON file name
output_json_file="output/10-prompts_output-7b-34b-0.json"

# Output text file name
output_txt_file="output/30-prompts_output-7b-34b-0.txt"

# Read prompts and their difficulty levels from the JSON file
easy_prompts=$(jq -r '.easy[].prompt' "$input_file")
hard_prompts=$(jq -r '.hard[].prompt' "$input_file")

# Combine prompts and difficulty levels into a single array
prompts=("$easy_prompts" "$hard_prompts")
difficulty_levels=("easy" "hard")

# Initialize variables to store time spent
total_large_model_time=0
total_small_model_time=0
total_deepmind_time=0
total_google_time=0

# Initialize arrays to store timing information and difficulty levels
timing_info=()
difficulty_info=()

IFS=$'\n' read -d '' -ra all_prompt_array <<< "$prompts"

i=0
# Loop through prompts
for prompt in "${all_prompt_array[@]}"; 
do
    # Print the current prompt
    echo "Current Prompt: $prompt"
    difficulty="${difficulty_levels[$i]}"

    # Generate the command
    command="python main.py --input \"$prompt\" --target_model_name codellama/CodeLlama-34b-Python-hf --approx_model_name codellama/CodeLlama-7b-Python-hf -v"

    # Execute the command and capture the output
    output=$(eval "$command")
    echo "${output}"

    # Capture and parse time spent from the output
    time_spent=$(echo "$output" | grep -Eo 'took [0-9]+\.[0-9]+ seconds' | awk '{print $2}')

    IFS=$'\n' read -ra times -d $'\0' <<< "$time_spent"

    value1_float=$(awk -v value1="${times[0]}" 'BEGIN { print value1 + 0 }')
    value2_float=$(awk -v value2="${times[1]}" 'BEGIN { print value2 + 0 }')
    value3_float=$(awk -v value3="${times[2]}" 'BEGIN { print value3 + 0 }')
    value4_float=$(awk -v value4="${times[3]}" 'BEGIN { print value4 + 0 }')

        

    # Update total time spent for each model
    total_large_model_time="$( bc <<<"$total_large_model_time + $value1_float" )"
    total_small_model_time="$( bc <<<"$total_small_model_time + $value2_float" )"
    total_deepmind_time="$( bc <<<"$total_deepmind_time + $value3_float" )"
    total_google_time="$( bc <<<"$total_google_time + $value4_float" )"

    # Create a JSON object for the timing information
    timing_object="{\"Prompt $((i + 1))\": {\"Large Model\": \"${times[0]} seconds\", \"Small Model\": \"${times[1]} seconds\", \"DeepMind\": \"${times[2]} seconds\", \"Google\": \"${times[3]} seconds\"}},"

    # Append the timing information to the array
    timing_info+=("$timing_object")

    # Create a JSON object for the difficulty information
    difficulty_object="{\"Prompt $((i + 1))\": \"$difficulty\"}"
    ((i+=1))

    # Append the difficulty information to the array
    difficulty_info+=("$difficulty_object")
    difficulty_info+=(",")

    echo "Done with ${prompt}"

done

# Create a JSON object to store the summary
summary="{\"Total Time\": {\"Large Model\": \"$total_large_model_time seconds\", \"Small Model\": \"$total_small_model_time seconds\", \"DeepMind\": \"$total_deepmind_time seconds\", \"Google\": \"$total_google_time seconds\"}}"

# Combine all timing information, difficulty information, and summary into a single JSON object
timing_info+=("$summary")
output_json="{\"Timing Information\": [${timing_info[*]}], \"Difficulty Information\": [${difficulty_info[*]}]}"

# Write the JSON object to the output JSON file
echo "$output_json" > "$output_json_file"

# Write the timing and difficulty information to the output text file
echo "$output_json" | jq -r '.' > "$output_txt_file"

echo "Timing and difficulty information saved to $output_json_file and $output_txt_file"
