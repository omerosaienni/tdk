# Notes

```graphql
mutation DeletePolicySetting($input: DeletePolicySettingInput!) {
  deletePolicySetting(input: $input) {
    value
  }
}
```

```graphql
mutation DeleteResource($input: DeleteResourceInput!) {
  deleteResource(input: $input) {
    turbot {
      id
    }
  }
}
```

```graphql
query GetPolicyType {
  policySettings(filter: "policyTypeId:tmod:@turbot/aws-s3#/policy/types/bucketApproved policyTypeLevel:self") {
    items {
      value
    }
  }
}
```

```graphql
{
  resources(filter: "resourceType:tmod:@turbot/aws#/resource/types/account $.Id:'688720832404'") {
    items {
      object
    }
  }
}
```
