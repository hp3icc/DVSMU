config.sh : Un programa que organiza el contenido principal de setup.sh. Actualmente no hay usos especiales.

dvsmu_ver: un archivo que muestra solo la versión de dvsMU (es necesario para aquellos que usan la versión 2.0 o anterior) Si actualiza dvsMU, debe cambiar el contenido de este archivo.

upgrade.sh : si actualiza desde el menú en el programa dvsMU, este archivo se ejecuta.

Carpeta PRINCIPAL: Entre los cambios en el archivo de imagen para distribución doméstica, el contenido es relevante solo para el usuario principal. 

            예를 들어, 추가모드(STFU, ASL)의 사용을 위해서 dvsm.sh, dvsm.macro, var.txt 등에 내용을 추가해야 한다.
            이런 파일은 주 사용자에게만 해당되고, 이미지파일에는 수정되지만, 기존 사용자에게는 전달할 방법이 없으므로,
            dvsmu의 upgrade시 적용이 되도록 한다.
                        
            upgrade.sh에 파일을 변경하는 루틴을 추가한다.
            var.txt은 파일을 변경하는 것이 아니고, 추가되는 변수만, upgrade.sh의 내용중 variable추가하는 루틴에 포함한다.


