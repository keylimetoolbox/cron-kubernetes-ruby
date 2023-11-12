# v2.0.0
**Breaking Change:**
- Requires ruby 2.7 or later

**Changes:**
- Fix issue where running `cron_kubernetes` would fail with "ResourceNotFoundError"

# v1.1.0
- Fix issue where all cron jobs in a cluster would be removed, not just ones matching `identifier`

# v1.0.0
**Breaking Change:**
- Requires `kubeclient` 3.1.2 or 4.x

 **Changes:**
- Add `kubeclient` configuration option for connecting to any Kubernetes server
- Add Appraisal for testing with kubeclient 3.1.2 and 4.x

# v0.1.0
- Initial Release
