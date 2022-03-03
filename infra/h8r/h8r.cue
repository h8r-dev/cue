package h8r

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/alpine"
)

// Create H8r Ingress, Service, Endpionts
#CreateH8rIngress: {
	// Ingress name
	name: dagger.#Input & {string}
	
	// Host IP
	host: dagger.#Input & {string}

	// Domain
	domain: dagger.#Input & {string}

	// Port
	port: dagger.#Input & {string | *"80"}

	create: {
		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash:         true
					package: curl:         true
					package: jq: true
					package: sed: true
				}
			},

			op.#Exec & {
				dir: "/root"
				env: {
					NAME:    name
					HOST: host
                    DOMAIN: domain
                    PORT: port
				}
				args: [
                    "/bin/bash",
                    "--noprofile",
                    "--norc",
                    "-eo",
                    "pipefail",
                    "-c",
                    #"""
					export HOST=$(echo $HOST | awk '$1=$1')
					echo '{"name":"'$NAME'","host":"'$HOST'","domain":"'$DOMAIN'","port":"'$PORT'"}'
					check=$(curl --insecure -X POST --header 'Content-Type: application/json' --data-raw '{"name":"'$NAME'","host":"'$HOST'","domain":"'$DOMAIN'","port":"'$PORT'"}' api.stack.h8r.io/api/v1/cluster/ingress | jq .message | sed 's/\"//g')
					if [ "$check" == "ok" ]; then
						echo "Create h8r ingress success"
					else
						echo "Create h8r ingress fail"
						exit 1
					fi
					"""#,
				]
				always: true
			},
		]
	}
}