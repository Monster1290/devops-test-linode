import json
import subprocess
import sys

from kubernetes import client
from kubernetes.client.rest import ApiException

if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Wrong number of input parameters. Required one parameter - name of deployment")

    deployment_name = sys.argv[1]

    proxy = subprocess.Popen(["kubectl", "proxy"], stdout=subprocess.PIPE)
    config = client.configuration.Configuration()
    config.host = "127.0.0.1:8001"
    api_client = client.ApiClient(configuration=config)
    api = client.CustomObjectsApi(api_client=api_client)

    # wait for output by proxy that means that proxy started serving
    proxy.stdout.read(1)
    try:
        # FIX: get name input
        canary_rollout = api.get_namespaced_custom_object(group="argoproj.io", version="v1alpha1", namespace="default",
                                               plural="rollouts", name=deployment_name)
    except ApiException as e:
        print("Exception when calling CustomObjectsApi->get_namespaced_custom_object: %s\n" % e)
        exit(1)

    proxy.terminate()

    canary_stages = [[]]
    stage_index = 0
    for step in canary_rollout["spec"]["strategy"]["canary"]["steps"]:
        if "pause" in step and "duration" not in step["pause"]:
            canary_stages.append([])
            stage_index += 1

        if "setWeight" in step:
            canary_stages[stage_index].append(str(step["setWeight"]))

    last_stage_index = len(canary_stages) - 1
    canary_stages[last_stage_index].append("100")
    print(json.dumps(canary_stages))

