NAME = f3lin/catalogue
DBNAME = f3lin/catalogue-db

TAG=$(COMMIT)

INSTANCE = catalogue

.PHONY: default copy test

default: test

release:
	docker build -t $(NAME) -f ./docker/catalogue/Dockerfile .

test: 
	GROUP=f3lin COMMIT=test ./scripts/build.sh
	./test/test.sh unit.py
	./test/test.sh container.py --tag $(TAG)

dockertravisbuild: build
	docker build -t $(NAME):$(TAG) -f docker/catalogue/Dockerfile-release docker/catalogue/
	docker build -t $(DBNAME):$(TAG) -f docker/catalogue-db/Dockerfile docker/catalogue-db/

