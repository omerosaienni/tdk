aly_alyce
#!/bin/bash

function command_exists() {
    # check if command exists and fail otherwise
    command -v "$1" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Command $1 is required but it's not installed" >&2
        exit 2
    fi
}

# Currently this script only targets AWS
TYPE="aws"

ACCOUNT_ID="688720832404"

# Parse the command line into values required by script
while (( "$#" )); do
    case "$1" in
        -a|--account-id)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                ACCOUNT_ID=$2
                shift 2
            else
                echo "[ERROR] Argument for $1 is missing" >&2
                exit 1
            fi
        ;;
        --help)
            echo "Mandatory arguments"
            echo "Optional arguments"
            exit 0
        ;;
        -*|--*=) # unsupported flags
            echo "[ERROR] Unsupported flag $1" >&2
            exit 1
        ;;
        *) # unsupported positional arguments
            echo "[ERROR] Error: Unsupported argument $1" >&2
            exit 1
        ;;
    esac
done

for COMMAND in "turbot" "jq"
do
    command_exists $COMMAND
done

# Get the Turbot id for the account id provided by the argument `--account-id`
ACCOUNT_QUERY='
{
    resources(filter:"resourceType:tmod:@turbot/aws#/resource/types/account $.Id:'${ACCOUNT_ID}'") {
        items {
            turbot {
                id
            }
        }
    }
}
'
ACCOUNT_TURBOT_ID=$(turbot graphql --query "$ACCOUNT_QUERY" --format json | jq -r '.resources.items[0].turbot.id')
if [ ${ACCOUNT_TURBOT_ID} == "null" ]
then
    echo "[ERROR] Unable to determine Turbot id for account id: ${ACCOUNT_ID}" >&2
fi

# Setting the policy `AWS > Turbot > Permissions` to `Enforce: None`

## Find current policies that were set
PERMISSIONS_POLICY_QUERY='
{
    policySettings(filter: "policyTypeId:tmod:@turbot/aws-iam#/policy/types/permissions policyTypeLevel:self resourceId:191926035367605") {
        items {
            turbot {
                id
            }
            value
            resource {
                turbot {
                    id
                    title
                }
            }
        }
    }
}
'

PERMISSIONS_POLICIES_RESULT=$(turbot graphql --query "$PERMISSIONS_POLICY_QUERY" --format json)
NUM_PERMISSIONS_POLICIES_RESULT=$(turbot graphql --query "$PERMISSIONS_POLICY_QUERY" --format json | jq -r '.policySettings.items|length' | head -1)

## For each found policies, remove the old policies
for (( PERMISSIONS_POLICIES_INDEX=0; PERMISSIONS_POLICIES_INDEX<"${NUM_PERMISSIONS_POLICIES_RESULT}"; PERMISSIONS_POLICIES_INDEX++))
do
    POLICY_SETTING_ID=$(jq -c ".policySettings.items[${PERMISSIONS_POLICIES_INDEX}] | .turbot.id" <<< "$PERMISSIONS_POLICIES_RESULT")
    POLICY_SETTING_VALUE=$(jq -c ".policySettings.items[${PERMISSIONS_POLICIES_INDEX}] | .value" <<< "$PERMISSIONS_POLICIES_RESULT")
    RESOURCE_ID=$(jq -c ".policySettings.items[${PERMISSIONS_POLICIES_INDEX}] | .resource.turbot.id" <<< "$PERMISSIONS_POLICIES_RESULT")
    RESOURCE_TITLE=$(jq -c ".policySettings.items[${PERMISSIONS_POLICIES_INDEX}] | .resource.turbot.title" <<< "$PERMISSIONS_POLICIES_RESULT")

    echo "[INFO] Removing setting ${POLICY_SETTING_VALUE} for resource ${RESOURCE_TITLE} with id ${RESOURCE_ID}"
done

## Setting `AWS > Turbot > Permissions` to `Enforce: None` at the account level
