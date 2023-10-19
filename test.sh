#!/bin/bash

# Input JSON file containing prompts and difficulty levels


configurations=($(jq -c '.[]' config.json))

# Loop through the array
for config in "${configurations[@]}"; do
    input_file=$(echo "$config" | jq -r '.input_file')
    output_file=$(echo "$config" | jq -r '.output_file')
    model1=$(echo "$config" | jq -r '.model1')
    model2=$(echo "$config" | jq -r '.model2')
    length=$(echo "$config" | jq -r '.length')

    # Now you can use the variables as needed
    echo "Input File: $input_file"
    echo "Output File: $output_file"
    echo "Model 1: $model1"
    echo "Model 2: $model2"
    echo "Length: $length"

# Read prompts and their difficulty levels from the JSON file
    prompts=$(jq -r '.[].prompt' "$input_file")



    # Initialize variables to store time spent
    total_large_model_time=0
    total_small_model_time=0
    total_deepmind_time=0
    total_google_time=0

    # Initialize arrays to store timing information and difficulty levels
    timing_info=""


    IFS=$'\n' read -d '' -ra all_prompt_array <<< "$prompts"

    i=0
    # Loop through prompts
    for prompt in "${all_prompt_array[@]}"; 
    do
        # Print the current prompt
        echo "Current Prompt: $prompt"

        # Generate the command
        command="python main.py --input \"$prompt\" --target_model_name \"$model1\" --approx_model_name \"$model2\" -v --max_tokens \"$length\""

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

        
        # Append the timing information to the array
        timing_object="\"Prompt $((i + 1))\": {
        \"Large Model\": \"${times[0]} seconds\",
        \"Small Model\": \"${times[1]} seconds\",
        \"DeepMind\": \"${times[2]} seconds\",
        \"Google\": \"${times[3]} seconds\"
        },"
        
        # Append the timing information to timing_info
        timing_info="${timing_info}"$'\n'"${timing_object}"

        echo "${timing_object}"
        ((i += 1))
        


        echo "Done with ${prompt}"

    done

    # Create a JSON object to store the summary
    summary="{\"Total Time\": {\"Large Model\": \"$total_large_model_time seconds\", \"Small Model\": \"$total_small_model_time seconds\", \"DeepMind\": \"$total_deepmind_time seconds\", \"Google\": \"$total_google_time seconds\"}}"


    # Combine all timing information, difficulty information, and summary into a single JSON object
    timing_info="${summary}${timing_info}"

    # Write the JSON object to the output JSON file
    echo "$timing_info" > "$output_file"

done