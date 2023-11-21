#!/bin/bash
set -e


function menu_rancher_assets() {
    echo "Select Rancher Assets Option:"
    echo "____________________________________________________________________________________________________________________________________"
    select choice in "Delete" "Download"; do
        case $choice in
            "Delete")
                delete_rancher_assets || true
                break
                ;;
            "Download")
                download_rancher_assets
                break
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
    echo "____________________________________________________________________________________________________________________________________"
}

function menu_k3s_images_txt() {
    echo "Select k3s-images.txt Option:"
    echo "____________________________________________________________________________________________________________________________________"
    select choice in "Delete" "Download"; do
        case $choice in
            "Delete")
                delete_k3s_assets || true
                break
                ;;
            "Download")
                download_k3s_assets
                break
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
    echo "____________________________________________________________________________________________________________________________________"
}