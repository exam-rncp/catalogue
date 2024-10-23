NAME = f3lin/catalogue
DBNAME = f3lin/catalogue-db

TAG=$(COMMIT)

INSTANCE = catalogue

.PHONY: default copy test

default: test

release:
	docker build -t $(NAME) -f ./docker/catalogue/Dockerfile .

test-unit:
	docker build -t test -f ./test/Dockerfile .
	docker run --rm test go test -v

# require docker compose
test-container: 
	chmod +x /test/test.sh
	./test/test.sh

dockerbuild:
	docker build -t $(NAME):$(TAG) -f docker/catalogue/Dockerfile-release docker/catalogue/
	docker build -t $(DBNAME):$(TAG) -f docker/catalogue-db/Dockerfile docker/catalogue-db/

