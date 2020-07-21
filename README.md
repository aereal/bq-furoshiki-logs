# bq-furoshiki-logs

Import [furoshiki2][] logs into BigQuery.

## Usage

```
mkdir -p logs
ruby collect_furo2_logs.rb # dump logs into logs/
GCP_SERVICE_ACCOUNT_JSON="$(cat ~/path/to/service-account.json | jq -c . | ruby -ruri -e 'puts URI.encode_www_form_component(ARGF.read)')" embulk run ./etc/embulk/furoshiki.yml.liquid
```

[furoshiki2]: https://github.com/motemen/furoshiki2
