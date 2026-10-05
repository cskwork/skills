# MongoDB

## Connect (credential-safe)

Preferred: the proven `mongodb-intelligence` toolkit if present in the project
(look for `mongodb-intelligence/` under the project's skill directories):

```bash
python scripts/config.py               # validate MONGO1..3 .env without secrets
python scripts/db_connector.py         # test connections
python scripts/schema_extractor.py     # samples 100 docs/collection → schema_metadata.json
```

Fallback: `mongosh` with the URI kept in the environment (never echoed):

```bash
mongosh "$MONGO_URI" --quiet --eval 'db.getCollectionNames()'
mongosh "$MONGO_URI" --quiet --eval 'JSON.stringify(db.orders.find({...}).limit(20).toArray())'
```

## Schema = inference (schemaless engine)

There is no catalog; the schema is a claim you verify by sampling:

```javascript
// field shape survey for one collection
db.orders.aggregate([
  { $sample: { size: 100 } },
  { $project: { kv: { $objectToArray: "$$ROOT" } } },
  { $unwind: "$kv" },
  { $group: { _id: { field: "$kv.k", type: { $type: "$kv.v" } }, n: { $sum: 1 } } },
  { $sort: { "_id.field": 1, n: -1 } }
])
db.orders.getIndexes()
```

- A field can hold **multiple types across documents** — the survey above
  exposes that; treat mixed types as a data-shape gotcha.
- Re-sample when documents look older/newer than the feature you're specifying;
  schema drifts silently.

## Entity graph

Mongo has no FKs. Edges come from:
- `*Id` / `*_id` fields whose values match another collection's `_id` (verify
  with a sampled `$lookup`),
- embedded sub-documents (containment edges),
- application code (mongoose refs, `$lookup` stages in the repo).

## Query

- Simple filters: `find(filter, projection).limit(n)`.
- Anything with grouping/joins/reshaping: aggregation pipeline. Put `$match`
  first (index use), `$limit` early, `$lookup` late and only on verified edges.
- Writes (`updateOne/Many`, `deleteOne/Many`): show the filter + a
  `countDocuments(filter)` of the blast radius, get approval, run, re-count.

## Engine-specific care

- `explain("executionStats")` — check `totalDocsExamined` vs `nReturned`;
  COLLSCAN on large collections is the red flag.
- Dates: BSON Date vs ISO string vs epoch number — `$type` survey tells you.
- `null` vs missing field are different: `{f: null}` matches both; use
  `$exists` to distinguish.
- Case-sensitive field names; `orderID` ≠ `orderId`.
