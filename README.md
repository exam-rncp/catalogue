[![ci](https://github.com/exam-rncp/catalogue/actions/workflows/main.yml/badge.svg)](https://github.com/exam-rncp/catalogue/actions/workflows/main.yml)


## Run tests before submitting PRs
`make test`

## To run the service
```bash
 $ chmod 644 build.sh
 $ ./build.sh
```

### Check whether the service is alive
`curl http://localhost:8080/health`

### Use the service endpoints
`curl http://localhost:8080/catalogue`

## Test Zipkin

To test with Zipkin

```bash
 $ docker-compose -f docker-compose-zipkin.yml build d
 $ docker-compose -f docker-compose-zipkin.yml up
```
It takes about 10 seconds to seed data

you should see it at:
[http://localhost:9411/](http://localhost:9411)

be sure to hit the "Find Traces" button.  You may need to reload the page.

when done you can run:
```bash
 $ docker-compose -f docker-compose-zipkin.yml down
```
