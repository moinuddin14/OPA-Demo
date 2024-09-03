#!/bin/bash

# Define file paths
REGO_FILE="local-dev/pod_security.rego" # The Rego file you want to use for updating
YAML_FILE="k8s/opa-configmap.yaml" # The Kubernetes YAML file to update
CONFIGMAP_KEY="pod_security.rego" # The key name in the ConfigMap to update in the YAML file
TEMP_FILE="temp-env/kubernetes_temp.yaml.temp" # The temporary file to create with the updated content

# Function to update the data section and create a new temp file
update_configmap() {
  awk -v configmap_key="$CONFIGMAP_KEY" -v rego_file="$REGO_FILE" '
    BEGIN {in_data_section=0; skip_content=0}
    
    # Match the beginning of the data section
    /^data:/ {in_data_section=1; print $0; next}

    # When we encounter the key, replace its content with the content from the Rego file
    in_data_section == 1 && $1 == configmap_key ":" {
      print "  " configmap_key ": |"
      while (getline line < rego_file) {
        print "    " line
      }
      skip_content=1
      next
    }

    # Skip over the old content under the key that we just replaced
    skip_content == 1 && /^    / {next}

    # If not in the data section, or after replacement, print the line as is
    {
      print $0
    }
  ' "$YAML_FILE" > "$TEMP_FILE"
}

# Main execution
echo "Creating a new temp file $TEMP_FILE with updated content from $REGO_FILE..."

# Check if the Rego file exists
if [ ! -f "$REGO_FILE" ]; then
  echo "Error: Rego file $REGO_FILE does not exist."
  exit 1
fi

# Check if the YAML file exists
if [ ! -f "$YAML_FILE" ]; then
  echo "Error: YAML file $YAML_FILE does not exist."
  exit 1
fi

# Update the YAML file and create a temporary file
update_configmap

echo "Temporary file $TEMP_FILE has been created. Please verify the contents."