Inspiration:

![Imgur](https://i.imgur.com/oezuysl.png)

### Pushing changes to git

User commits her changes and pushes them to a development branch. All tests on her code tree are automatically run and she can see the results in a test results UI, linked from GitHub.

She then asks for a peer review and the code is merged into the master branch. Tests are run again. If any test fails, Jessica receives a warning about post-merging test failures.

See [Bababot](Bababot.md).

### Release and Deploy

Once the new service is merged into master, a continuous deployment pipeline is automatically setup. All service environments are registered and available for service discovery.

Since Jessica decided to make this service available externally, a public URL is automatically created for the staging and development instances.

This service should only be used by the company's own clients (javascript broser clients and CLI), Jessica enabled auth enforcement for this service. The reverse proxy will only forward requests that contain valid application and user credentials in the gRPC call.

#### Recap
* fully automated
* reliability SLOs from day one

