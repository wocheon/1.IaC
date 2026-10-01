#!/bin/bash

DESC=(
    ""
    "Terraform Plan"
    "Terraform Apply"
    "Terraform Destroy"
)

CMD_TEXT=(
    ""
    "terraform plan"
    "terraform apply --auto-approve"
    "terraform destory --auto-apporve"
)

run_cmd1() {
    terraform plan
}

run_cmd2() {
    terraform apply --auto-approve
}

run_cmd3() {
    terraform destroy --auto-approve
}

while true; do
    echo
    echo "===== MENU ====="

    for i in 1 2 3; do
        printf "%d) %-20s -> %s\n" \
            "$i" \
            "${DESC[$i]}" \
            "${CMD_TEXT[$i]}"
    done

    echo "0) 종료"
    echo "================"

    read -rp "선택: " choice

    case "$choice" in
        1|2|3)
            echo
            echo "[실행 작업] ${DESC[$choice]}"
            echo "[실행 명령] ${CMD_TEXT[$choice]}"
            echo "--------------------------------"

            "run_cmd${choice}"
            ;;
        0)
            echo "종료합니다."
            break
            ;;
        *)
            echo "잘못된 입력입니다."
            ;;
    esac
done
