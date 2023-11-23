#!/bin/bash

# Define Log4j version
log4j_version="2.22.0"

# URL of the log4j zip file
log4j_url="https://dlcdn.apache.org/logging/log4j/${log4j_version}/apache-log4j-${log4j_version}-bin.zip"

# Destination directory
destination="/root/apache-${log4j_version}"

# Additional search path for log4j*.jar files
search_path="/opt/arkcase/"

# Function to initialize Log4j
initialize_log4j() {
  local destination=$1

  # Create the destination directory if it doesn't exist
  mkdir -p $destination

  # Download the log4j zip file
  curl -k -L -o $destination/apache-log4j-${log4j_version}-bin.zip $log4j_url

  # Navigate to the destination directory
  cd $destination

  # Unzip the downloaded file
  unzip apache-log4j-${log4j_version}-bin.zip
}

# Function to copy Log4j ${log4j_version} JAR files to the folder of the zipped file
copy_log4j_files() {
  local zipped_folder=$1
  cp $destination/log4j-1.2-api-${log4j_version}.jar $destination/log4j-api-${log4j_version}.jar $destination/log4j-core-${log4j_version}.jar "$zipped_folder"

  # Get permissions
  # Get and print the user and group of the current directory
  user=$(stat -c "%U" "$zipped_folder")
  group=$(stat -c "%G" "$zipped_folder")
  permissions=$(stat -c "%a" "$zipped_folder")
  echo "User=$user   Group=$group    Permissions=$permissions"

  # Change permissions accordingly
  chown $user:$group $zipped_folder/log4j-1.2-api-${log4j_version}.jar $zipped_folder/log4j-api-${log4j_version}.jar $zipped_folder/log4j-core-${log4j_version}.jar

  echo "Copied Log4j ${log4j_version} JAR files to $zipped_folder"
}

# Define a function to stop the arkcase service
stop_arkcase_service() {
  # Stop arkcase service
  systemctl stop arkcase.service

  # Check if the service is still running
  while systemctl status "$service_name" > /dev/null 2>&1; do
      echo "Waiting for $service_name to stop..."
      sleep 1
  done
  echo "$service_name stopped successfully."
}

# Function to process found log4j 1.2.17 JAR files
process_log4j_files() {
  local log4j_jar_files=$1

  # Display the found log4j 1.2.17 JAR files
  if [ -n "$log4j_jar_files" ]; then
    # Call the function to stop the arkcase service
    stop_arkcase_service

    echo "Found the following log4j 1.2.17 JAR files in $search_path:"
    echo "$log4j_jar_files"

    # Call the function to initialize Log4j
    initialize_log4j $destination

    # Call the function to copy Log4j ${log4j_version} JAR files to the folder of the zipped file
    for file in $log4j_jar_files; do
      zip_file="${file%.jar}.zip"
      zip -j $zip_file $file
      echo "File $file zipped as $zip_file"
      
      echo "Removing file $file"
      rm $file 
      
      copy_log4j_files "$(dirname $file)"
    done
  else
    echo "No log4j 1.2.17 JAR files found in $search_path."
  fi
}

# Call the function to process found log4j 1.2.17 JAR files
log4j_jar_files=$(find $search_path -name 'log4j*1.2.17*.jar')
process_log4j_files "$log4j_jar_files"
