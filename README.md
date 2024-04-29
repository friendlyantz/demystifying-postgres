# Indexing

```sh
docker run --name demystifying-postgres \
-e POSTGRES_PASSWORD=password \
-e POSTGRES_USER=$(whoami) \
-e POSTGRES_DB=index_test \
-p 5432:5432 \
-d postgres
```
