# Seatable Python Runner

Based on the [official installation manual](https://manual.seatable.io/docker/Python-Runner/Deploy%20SeaTable%20Python%20Runner/) with some adjustments.

* This runner can work in a k8s dind environment
* The script creates a new subdirectory to share data with the dind service container
* The entrypoint combines the init and start scripts.

Update `VERSION` variable in `.env` to align with official release.
