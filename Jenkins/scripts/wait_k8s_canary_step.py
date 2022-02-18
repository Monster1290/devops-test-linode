import subprocess
import sys

from kubernetes import client, watch
from kubernetes.client.rest import ApiException

if __name__ == "__main__":
    desired_step = int(sys.argv[1])
    proxy = subprocess.Popen(["kubectl", "proxy"], stdout=subprocess.PIPE)
    config = client.configuration.Configuration()
    config.host = "127.0.0.1:8001"
    api_client = client.ApiClient(configuration=config)
    api = client.CustomObjectsApi(api_client=api_client)
    w = watch.Watch()

    # wait for output by proxy that means that proxy started serving
    proxy.stdout.read(1)

    try:
        # FIX: get name input
        canary_rollout = api.get_namespaced_custom_object(group="argoproj.io", version="v1alpha1", namespace="default",
                                               plural="rollouts", name="rollouts-demo")

    except ApiException as e:
        print("Exception when calling CustomObjectsApi->get_namespaced_custom_object: %s\n" % e)
        exit(1)

    canary_rollout_steps = canary_rollout["spec"]["strategy"]["canary"]["steps"]
    desired_step_index = -1
    if desired_step == "100":
        desired_step_index = len(canary_rollout_steps)
    else:
        for i in range(0, len(canary_rollout_steps)):
            if "setWeight" in canary_rollout_steps[i] and canary_rollout_steps[i]["setWeight"] == desired_step:
                desired_step_index = i
                break

    if desired_step_index == -1:
        print(f'Weight ${desired_step} not present in rollout deployment')
        exit(1)

    for event in w.stream(api.list_namespaced_custom_object, group="argoproj.io", version="v1alpha1",
                          namespace="default", plural="rollouts"):
        etype = event["type"]
        name = event["object"]["metadata"]["name"]

        # FIX: get name input
        if (etype != "ADDED" or etype != "MODIFIED") and name != "rollouts-demo":
            continue

        step_index = int(event["object"]["status"]["currentStepIndex"])

        if desired_step_index <= step_index:
            break

    proxy.terminate()
