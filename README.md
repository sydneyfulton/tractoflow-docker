Tractoflow-docker Readme

# tractoflow-docker

A docker for running **Tractoflow Pipeline**


___


## Build (Docker)

To build the Docker image locally:

```docker build -t tractoflow:latest```

## Run (Docker)

To run the docker:
 ```docker run -it --rm   -v <your_data_dir>:/data    tractoflow:latest   tractoflow     --input <subjects_dir>      --output_dir <output_dir>     -with-singularity /tractoflow/scilus_1.6.0.sif  ```   

___________


