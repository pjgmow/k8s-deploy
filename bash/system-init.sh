#!/bin/bash

# CentOS 7.9

# 配置时间同步服务
echo "###############"
yum install -y chrony
systemctl enable chronyd && systemctl restart chronyd
systemctl status chronyd
echo "###############"

# 关闭防火墙
echo "###############"
systemctl disable firewalld && systemctl stop firewalld
systemctl status firewalld
echo "###############"

# 关闭selinux安全服务
echo "###############"
sed -i "s@^\(SELINUX\)=.*@\1=disabled@" /etc/selinux/config && setenforce 0
grep "^SELINUX=" /etc/selinux/config
echo "###############"

# 关闭swap分区
echo "###############"
swapoff -a && sed -i '/swap/ s@^\(.*\)@\#\1@g' /etc/fstab
egrep -v "^#|^$" /etc/fstab
echo "###############"

# 配置contrainerd容器运行时
echo "###############"
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
echo "###############"

# 启用ipvs
echo "###############"
# CentOS 7.9 默认内核版本是3.10
# 内核版本4.18以下使用nf_conntrack_ipv4
# 内核版本4.18以上使用nf_conntrack
yum install -y ipset ipvsadm
cat <<EOF | tee /etc/modules-load.d/ipvs.conf
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
nf_conntrack_ipv4
EOF
echo "###############"

# 配置limit参数
echo "###############"
cat <<EOF | tee /etc/security/limits.d/20-nproc.conf 
*   	soft    nproc	65535
root	soft    nproc	unlimited
*   	hard    nproc	65535
root	hard    nproc	unlimited
*   	soft    nofile	65535
*   	hard	nofile	65535
EOF

cat <<EOF | tee /etc/systemd/system.conf
[Manager]
DefaultLimitCORE=infinity
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF

cat <<EOF | tee /etc/systemd/user.conf
[Manager]
DefaultLimitCORE=infinity
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF
echo "###############"

# 配置kernel参数
echo "###############"
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
EOF
echo "###############"
