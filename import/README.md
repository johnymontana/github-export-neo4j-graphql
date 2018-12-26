First follow the [steps to download all of your GitHub data](https://blog.github.com/2018-12-19-download-your-data/). You will receive a series of JSON files. Note the path to these files and set as a `baseURL` parameter. 

for example, in Neo4j Browser:

```
:param baseURL:"file:///Users/lyonwj/Desktop/"
```

Then run `load_data.cypher` to import this data into Neo4j.