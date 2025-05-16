***All demos have been tested against Ubuntu 22.04 and Kubernetes 1.26.0***

There may be slight differences in the code from what's in the video course, but the concepts are all the same.
* Update 19 Feb 2023
  * Changed containerd installation repo to docker's. 1.6 is required and the ubuntu's repo only provides 1.5.9
  * Moved hello-app to a new container repository, the gcr application changed and no longer works for demos.

* Update 20 Aug 2022
  * The course downloads have been updated and tested with 1.24.3. 
  * gpg key and apt repository add code changed. Updated to match current syntax

* Update 27 Mar 2022
  * The course downloads have been updated and tested with 1.23.4. 
  * The installation of containerd and the bootstrapping of a cluster with kubeadm are dramatically simpler than in the 1.21 version which is what's in the course video at the moment.

* Key updates
  * Setting the systemd cgroup driver in config.toml...the two lines I added in the video are now there by default. You just have to change SystemdCgroup = false to SystemdCgroup = true
  * You no longer need to create and edit ClusterConfiguration.yaml 
  * kubeadm 1.22 removed the need to use the parameters --config=ClusterConfiguration.yaml and --cri-socket /run/containerd/containerd.sock these parameters are no longer needed

If you have any issues please feel free to reach out in the course discussion page.

aen@centinosystems.com or in the course discussion page at www.pluralsight.com

