#!/bin/bash

# Function to print usage information
usage() {
    echo "Usage: $0 -d <directory> -m <months>"
    echo "  -d: Directory of the git repository"
    echo "  -m: Number of months to generate history for"
    exit 1
}

# Parse command-line arguments
while getopts ":d:m:" opt; do
    case $opt in
        d) dir="$OPTARG" ;;
        m) months="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
    esac
done

# Validate inputs
if [ -z "$dir" ] || [ -z "$months" ]; then
    usage
fi

if ! [[ "$months" =~ ^[0-9]+$ ]]; then
    echo "Error: Months must be a positive integer."
    exit 1
fi

# Check if the specified directory exists
if [ ! -d "$dir" ]; then
    echo "Error: Directory '$dir' does not exist."
    exit 1
fi

# Change to the specified directory
cd "$dir" || exit 1

# Initialize git repository if not already initialized
if [ ! -d .git ]; then
    git init
fi

# Create worklog.md if it doesn't exist
touch worklog.md

# Calculate the start date
start_date=$(date -v-"${months}"m +%Y-%m-%d)

# Function to get a random line from a file
get_random_line() {
    sort -R "../$1" | head -n 1
}

# Function to add days to a date
add_days() {
    date -v+"$2"d -j -f "%Y-%m-%d" "$1" +%Y-%m-%d
}

# Function to generate a random time between 9am and 11pm
random_time() {
    hour=$((RANDOM % 15 + 9))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    printf "%02d:%02d:%02d" $hour $minute $second
}

# Function to update progress bar
update_progress() {
    local progress=$1
    local total=$2
    local commits_made=$3
    local total_commits=$4
    local width=50
    local percentage=$((progress * 100 / total))
    local completed=$((width * progress / total))
    local remaining=$((width - completed))
    printf "\r[%-${width}s] %d%% [%d/%d git commits made]" "$(printf "%${completed}s" | tr ' ' '#')" "$percentage" "$commits_made" "$total_commits"
}

# Calculate total days
start_seconds=$(date -j -f "%Y-%m-%d" "$start_date" +%s)
end_seconds=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m-%d)" +%s)
total_days=$(( (end_seconds - start_seconds) / 86400 + 1 ))

# Estimate total commits (assuming an average of 3 commits per day, 5 days a week)
total_commits=$((total_days * 3 * 5 / 7))

# Loop through each day from start_date to today
current_date="$start_date"
end_date=$(date +%Y-%m-%d)
day_count=0
commits_made=0

while [ "$current_date" != "$(add_days "$end_date" 1)" ]; do
    # Update progress bar
    update_progress $day_count $total_days $commits_made $total_commits

    # Determine if it's a work day (4-6 days per week)
    day_of_week=$(date -j -f "%Y-%m-%d" "$current_date" +%u)
    if [ "$day_of_week" -le $((RANDOM % 3 + 4)) ]; then
        # Generate 1-6 random commits for this day
        num_commits=$((RANDOM % 6 + 1))
        for ((i=1; i<=num_commits; i++)); do
            # Generate a random time for this commit
            commit_time=$(random_time)
            full_date="${current_date}T${commit_time}"

            # Add a random journal entry to worklog.md
            echo "## $full_date" >> worklog.md
            get_random_line "journalentries.txt" >> worklog.md
            echo "" >> worklog.md

            # Stage the changes
            git add worklog.md

            # Commit with a random commit message
            commit_message=$(get_random_line "commitmessages.txt")
            TZ='America/Los_Angeles' GIT_AUTHOR_DATE="$full_date" GIT_COMMITTER_DATE="$full_date" git commit -m "$commit_message" >/dev/null 2>&1
            
            ((commits_made++))
        done
    fi

    # Move to the next day
    current_date=$(add_days "$current_date" 1)
    ((day_count++))
done

# Complete the progress bar
update_progress $total_days $total_days $commits_made $total_commits
echo

# Return to the original directory
cd - > /dev/null

echo "Git history generation complete. Total commits made: $commits_made"