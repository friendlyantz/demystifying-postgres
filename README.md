# Indexing

```sh
# cd into dir
rake -T
```

docker script is part of rake, but here it is

```sh
docker run --name demystifying-postgres \
-e POSTGRES_PASSWORD=password \
-e POSTGRES_USER=$(whoami) \
-e POSTGRES_DB=index_test \
-p 5432:5432 \
-d postgres
```

Some findings:
ILIKE with wildcard on both sides vs only on the right side:  little difference. both sides is slower 10-20%
wildcard provided little, to no benefit to ILIKE, however if data after wildcard was more or less identical, it was magnitudes faster. i.e. ABDCSSA-predictable_string_replaced_by_wildcard
Partial index scan (~20%) - provided substantial improvement too, perhaps proportional to the size of the index, but not sure.

```
Time to find by symbol in UnindexedCompany: 111.06999998446554 milliseconds
Time to find by symbol in IndexedCompany: 1.0400000028312206 milliseconds
IndexedCompany is 106.8 times faster than UnindexedCompany

Time to find by symbol in PartialIndexedCompany: 81.54300000751391 milliseconds

Time to find in UnindexedCompany with ILIKE no wildcard: 206.3559999805875 milliseconds
Time to find in UnindexedCompany with ILIKE and wildcard on BOTH sides: 223.65699999500066 milliseconds
Time to find in UnindexedCompany with ILIKE and wildcard ONLY on the RIGHT side: 205.97499998984858 milliseconds
```

Also I noted hitting Partially indexed table second time with the same query (outside index range) was 100x faster, while others did not change (edited)
