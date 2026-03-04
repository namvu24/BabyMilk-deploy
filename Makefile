CHART_DIR := charts/babymilk
NAMESPACE := babymilk
RELEASE := babymilk

.PHONY: install upgrade uninstall status lint template

lint:
	helm lint $(CHART_DIR) -f $(CHART_DIR)/values-local.yaml

template:
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-local.yaml -n $(NAMESPACE)

install:
	helm upgrade --install $(RELEASE) $(CHART_DIR) \
		-f $(CHART_DIR)/values-local.yaml \
		-f $(CHART_DIR)/values-local-secrets.yaml \
		-n $(NAMESPACE) --create-namespace --wait

upgrade: install

uninstall:
	helm uninstall $(RELEASE) -n $(NAMESPACE)

status:
	helm status $(RELEASE) -n $(NAMESPACE)
	kubectl get all -n $(NAMESPACE)
