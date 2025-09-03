@test "validate multiple client CA certificates" {
    teardown() {
        echo "cleaning up"
        wait_for_process ${WAIT_TIME} ${SLEEP_TIME} 'kubectl delete secret first-client-ca --namespace ${RATIFY_NAMESPACE} --ignore-not-found=true'
        wait_for_process ${WAIT_TIME} ${SLEEP_TIME} 'kubectl delete secret second-client-ca --namespace ${RATIFY_NAMESPACE} --ignore-not-found=true'
        wait_for_process ${WAIT_TIME} ${SLEEP_TIME} 'kubectl delete -f test/bats/tests/config/config_v1beta1_multi_client_ca.yaml -n ${RATIFY_NAMESPACE} --ignore-not-found=true'
        wait_for_process ${WAIT_TIME} ${SLEEP_TIME} 'rm -f test/bats/tests/certificates/multi-ca/*.crt test/bats/tests/certificates/multi-ca/*.key'
    }

    # Generate test certificates
    cd test/bats/tests/certificates/multi-ca
    chmod +x generate-certs.sh
    ./generate-certs.sh
    cd -

    # Create first CA cert secret
    kubectl create secret generic first-client-ca \
        --from-file=ca.crt=test/bats/tests/certificates/multi-ca/first-ca.crt \
        -n ${RATIFY_NAMESPACE}
    assert_success

    # Create second CA cert secret
    kubectl create secret generic second-client-ca \
        --from-file=ca.crt=test/bats/tests/certificates/multi-ca/second-ca.crt \
        -n ${RATIFY_NAMESPACE}
    assert_success

    # Apply configuration with multiple CA certs
    kubectl apply -f test/bats/tests/config/config_v1beta1_multi_client_ca.yaml -n ${RATIFY_NAMESPACE}
    assert_success

    # Wait for configuration to be applied
    sleep 30

    # Test first client certificate authentication
    curl --fail --silent \
        --cert test/bats/tests/certificates/multi-ca/first-client.crt \
        --key test/bats/tests/certificates/multi-ca/first-client.key \
        --cacert test/bats/tests/certificates/multi-ca/first-ca.crt \
        https://localhost:6001/healthz
    assert_success

    # Test second client certificate authentication
    curl --fail --silent \
        --cert test/bats/tests/certificates/multi-ca/second-client.crt \
        --key test/bats/tests/certificates/multi-ca/second-client.key \
        --cacert test/bats/tests/certificates/multi-ca/second-ca.crt \
        https://localhost:6001/healthz
    assert_success

    # Test certificate rotation by updating first CA
    kubectl create secret generic first-client-ca \
        --from-file=ca.crt=test/bats/tests/certificates/multi-ca/first-ca.crt \
        --dry-run=client -o yaml | kubectl replace -f -
    assert_success

    # Wait for certificate rotation
    sleep 30

    # Test authentication still works with new client cert
    curl --fail --silent \
        --cert test/bats/tests/certificates/multi-ca/first-client-new.crt \
        --key test/bats/tests/certificates/multi-ca/first-client-new.key \
        --cacert test/bats/tests/certificates/multi-ca/first-ca.crt \
        https://localhost:6001/healthz
    assert_success
}
