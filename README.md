config.sh : setup.sh의 주요 내용을 정리한 프로그램. 현재 특별한 용도는 없음.

dvsmu_ver : dvsMU의 ver만 표시한 파일.(ver2.0 이전을 사용하는 사람들에게는 꼭 필요함) dvsMU를 upgrade하면, 필히 이 파일의 내용을 변경하여야 한다.

upgrade.sh : dvsMU 프로그램내의 메뉴에서 upgrade하면 이 파일이 실행된다.

MAIN 폴더 : 국내배포용 이미지파일에 변경되는 내용 중 주사용자에게만 관련되는 내용.

            예를 들어, 추가모드(STFU, ASL)의 사용을 위해서 dvsm.sh, dvsm.macro, var.txt 등에 내용을 추가해야 한다.
            이런 파일은 주 사용자에게만 해당되고, 이미지파일에는 수정되지만, 기존 사용자에게는 전달할 방법이 없으므로,
            dvsmu의 upgrade시 적용이 되도록 한다.
                        
            upgrade.sh에 파일을 변경하는 루틴을 추가한다.
            var.txt은 파일을 변경하는 것이 아니고, 추가되는 변수만, upgrade.sh의 내용중 variable추가하는 루틴에 포함한다.


