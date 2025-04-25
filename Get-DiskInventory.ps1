<#
.SYNOPSIS
Get-DiskInventory retrieves logical disk information from all computers
of a given Organisational Unit.
.DESCRIPTION
Get-DiskInventory uses CIM to retrieve the Win32_LogicalDisk
instances. The users is promted to supply the value for the paramets of OU
and minimum free space of its drive. It displays each disk's
drive letter, free space, total size, percentage of free space of all 
computers below the given precentage and the amount of student profiles
on each disk. 
The drivetype is set to 3 (local disk) as default.
.PARAMETER OU
The Organisational Unit name to query. No default value.
.PARAMETER Free
The minimum free space percentage to query. No default value.
The drive type to query. 
See Win32_LogicalDisk documentation for values. 
.EXAMPLE
EXAMPLE 1
Get-DiskInventory.ps1
EXAMPLE 2
Get-DiskInventory.ps1 "NCL STU M228" 60
Example 3
Get-DiskInventory.ps1 -OU "Trevelyan T710" -Free 15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $OU,
    [Parameter(Mandatory=$true)]
    $Free
    )
    
    #Find the Organisational Unit from $OU and get the Distinguished Name and Name properties.
    $OUname = Get-ADOrganizationalUnit -Filter "Name -like '*$OU'" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $OUDN = Get-ADOrganizationalUnit -Filter "Name -like '*$OU'" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DistinguishedName
    write-output $OUname

    #If the OU is not found, exit
    if ($OUDN -eq $null) {
        Write-Host "Organisational Unit not found."
        exit
    }

else {

     #If more than one OU is found exit.
     $OUCount = ($OUDN).Count
    if ($OUCount -gt 1) {
        Write-Host "Too many Organisational Unit found, consider being more precise please."
        exit
    }
    else {

    #If the OU is found, get the computers in the OU
    $PCS = Get-ADComputer -LDAPFilter "(name=*)" -SearchBase $OUDN -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $PCSCount = ($PCS).Count

    #If no computers are found in the OU, exit.
    if ($PCSCount -eq 0) {
        Write-Host "No computers found in the Organisational Unit."
        exit
    }
    
    else {
    #CIM query to get the logical disks, free space, size, percentage of free space and the amount of student profiles on each disk
    Get-CimInstance -classname Win32_LogicalDisk -computername $PCS -filter "drivetype=3" -ErrorAction SilentlyContinue | Where-Object { ($_.FreeSpace / $_.Size * 100) -lt $Free } | Format-Table -property PSComputerName,
    @{label='AD Organisational Unit';expression={(Get-ADComputer $_.PSComputerName -Properties CanonicalName).CanonicalName -Split ("/") | Select-Object -Last 2 | Select-Object -First 1}},
    @{label='Device';expression={$_.DeviceID}},
    @{label='Size(GB)';expression={$_.Size /1GB -as [int]}},
    @{label='FreeSpace(GB)';expression={$_.FreeSpace /1GB -as [int]}},
    @{label='%Free';expression={$_.FreeSpace / $_.Size * 100 -as [int]}},
    @{label='StudentProfiles';expression={(Get-CimInstance -Class Win32_UserProfile -computername $_.PSComputerName | Where-Object {$_.LocalPath -like "C:\Users\s[0-9][0-9]*"} | Select-Object -Property LocalPath).Count}}
    }

}
}
#End of script

# SIG # Begin signature block
# MIIOZQYJKoZIhvcNAQcCoIIOVjCCDlICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD47t752GYJVdrw
# AvMBC+w/q4vH0hYqxtKjrnpA0ZoR8qCCC68wggU9MIIDJaADAgECAhN8AAAAE6EB
# Xl/JBNfaAAAAAAATMA0GCSqGSIb3DQEBCwUAMEAxEzARBgoJkiaJk/IsZAEZFgNv
# cmcxFTATBgoJkiaJk/IsZAEZFgVuY2dycDESMBAGA1UEAxMJTkNHUm9vdENBMB4X
# DTI0MTEyNjE0MzU1NFoXDTI5MTEyMDExMTQxN1owQzETMBEGCgmSJomT8ixkARkW
# A29yZzEVMBMGCgmSJomT8ixkARkWBW5jZ3JwMRUwEwYDVQQDEwxOQ0ctTkNMU3Vi
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC4zm8zmgrYrJ0n7ypp
# qSE5Us1zDV/r8ycBEGtgTb5oSnLVOrFhatsnh9tGhLXV/uMFh6Yb4gQ7fBzACeX1
# zNC6Gf/BM3gqVfb3x2CTM9MDqdmM9rGWLr5uVzQQLcS33pi6xRzAhpW4CLw0OUKn
# w+4VnyFsZ8Qc+nj+gGDdBTifD+9aYLwLg8DmUA7Ye6ZFxi89l2/R56IiO1wJyvCX
# YzXPy4gVY2SaGqo97CfDIlT5QlCLF/46JytezfUoPTvi3KiFxABhVEur3q0dSEww
# AUDgj9RZNbHEFRCqkELgb+Y2XueOJJrXqzdBmZ8ch2UodRkc9wEbxrUVy6Ryu7Fk
# nvcpAgMBAAGjggErMIIBJzASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcV
# AgQWBBQSukhCXChBvclqWfeTToPyqhUVgzAdBgNVHQ4EFgQUopsO4FPL23/EBV9P
# oHif1UNXZDwwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUemZAPrGPUSvJIw/EUEzI6eid
# Az8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL3BraS5uY2dycC5vcmcvbmNncm9v
# dGNhLmNybDA+BggrBgEFBQcBAQQyMDAwLgYIKwYBBQUHMAKGImh0dHA6Ly9wa2ku
# bmNncnAub3JnL25jZ3Jvb3RjYS5jcnQwDQYJKoZIhvcNAQELBQADggIBAGP2rqxn
# SolxvLMCjbVKXNeiWTDMNdCTEGv53Tt48k5LdmvWFLxScdEzjqkpvE6e6qAa5wsU
# lxyBtlg5We7BWZbCvOBkVb1BWFjpVbJkuqRKvHHSIrc72PXbbAqPnuXKaWvALa3x
# Q5/hocjPeXRRMex/BmPxC0r+S7N2wM/v9jt0CT4a+fYSuZloo+O4aVt9pjy1NkZ3
# r3gm5yP1caNnx3DlH3EqbN685zL27GBic9QB1uTzbSwiP8ujDAUAiD2ApTSmjh9/
# qNxWt0qpDxdsBFWLrtQSjPGPGrV0EKZmFJ7W6CPMd3z8Q6LjCDJlCtCfGdTFvh3c
# Xm5F1Iq5JEZZ1vLuzBS0PiUKZ0Zq1J9IpNTSw3VFpNiwzLJeV7seJ+z5TKOQMBsP
# kdiwrQbFF4R+KBAwKoigxT071wjbsIS62mxB7KcHj9mxHy+lZhrOc7aNkca3/3Ja
# cMBzTkmd9tYg/0UNNQ2aGHyIEZNlQVJVb2vIJcdXQjyCGuq9cPVAjvzgMQ/swlEq
# IBQNt5oTFC4xSUDgYF+upn48ZtFbjeFeStz0JXpxf0ffGOtBR9FyXHfkVq1ifFiY
# NfLDgOGOz9QSaiVSLVq6+RHOZsnSB/FNdJKACKCvJTHwnbT+2ZHAkuDZX0nyX9Ff
# TrF2RvFwo3LfPl0vz6iklPGO96n6L7Y5d73AMIIGajCCBVKgAwIBAgITEAADtczw
# hCwXBKZYMQABAAO1zDANBgkqhkiG9w0BAQsFADBDMRMwEQYKCZImiZPyLGQBGRYD
# b3JnMRUwEwYKCZImiZPyLGQBGRYFbmNncnAxFTATBgNVBAMTDE5DRy1OQ0xTdWJD
# QTAeFw0yNTA0MDkxMzUxMThaFw0yNzA0MDkxNDAxMThaMIG3MRMwEQYKCZImiZPy
# LGQBGRYDb3JnMRUwEwYKCZImiZPyLGQBGRYFbmNncnAxIDAeBgNVBAsTF05DRyBV
# c2VycyBhbmQgQ29tcHV0ZXJzMRkwFwYDVQQLExBVc2VycyBhbmQgR3JvdXBzMR0w
# GwYDVQQLExRHUlAgVXNlcnMgYW5kIEdyb3VwczEYMBYGA1UECxMPR1JQIFN0YWZm
# IFVzZXJzMRMwEQYDVQQDEwpEYXZpZCBTb2xlMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEArV/oHd/0bnB08zdGMTu84d8U+WpAwKrDSLM3oG2B3Y2UULIi
# tzBMfYRVYYXv7tzyqQLhPvJFzKKjsMfxRq6GpqOBEsNBScpO2rw5VA67r5cNAO34
# cBprIVlwUKepvrvANtyFSjPqrsqe6JRlxmGC5CwQTLXZcm+qm3zOCO1K29jkQuzx
# UyHfeDkkTpSTymX9KYT4o64Mb62TMyefrtIuC4RDZGBRuwSg+Lyvj0bHMF756SpZ
# IMCqcXxn4HvsR3jW4r4y5/jmESdBJZ52vaYQdJHzQtlwiTz+FFCM2/kXLB5ioses
# wCnpH7ORZk5K4PZvuR2AvKE81Oshcurt3tpz6QIDAQABo4IC4DCCAtwwPQYJKwYB
# BAGCNxUHBDAwLgYmKwYBBAGCNxUIx5F+gZCNe4LlkyCG6swzgajML4E9hpK0d4ao
# lFsCAWQCARgwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsG
# CSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFLMxNRcM+74K3IUl
# mbixLYHecszxMCoGA1UdEQQjMCGgHwYKKwYBBAGCNxQCA6ARDA9Ec29sZUBuY2dy
# cC5vcmcwHwYDVR0jBBgwFoAUopsO4FPL23/EBV9PoHif1UNXZDwwgfcGA1UdHwSB
# 7zCB7DCB6aCB5qCB44aBtmxkYXA6Ly8vQ049TkNHLU5DTFN1YkNBKDEpLENOPXZz
# LW5jbC1jYSxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vy
# dmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1uY2dycCxEQz1vcmc/Y2VydGlmaWNh
# dGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlv
# blBvaW50hihodHRwOi8vcGtpLm5jZ3JwLm9yZy9OQ0ctTkNMU3ViQ0EoMSkuY3Js
# MIHyBggrBgEFBQcBAQSB5TCB4jCBqQYIKwYBBQUHMAKGgZxsZGFwOi8vL0NOPU5D
# Ry1OQ0xTdWJDQSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049
# U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1uY2dycCxEQz1vcmc/Y0FDZXJ0
# aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkw
# NAYIKwYBBQUHMAKGKGh0dHA6Ly9wa2kubmNncnAub3JnL05DRy1OQ0xTdWJDQSgx
# KS5jcnQwDQYJKoZIhvcNAQELBQADggEBAHXtEr7u5uo5ftMGP6LC3/1MuAVKPS6H
# M2MwzQLuIN6QcCb0MDRoKaB1VU64jOarbOMIE7biN5G6neZhPRFunKVl63uiLbTX
# unSuSaFeqOqQO8Jl+4ifzfSJ9aeJq03NlL7RF2Y9Vaa8aQNdLfUc+Uki8jEtT46W
# VqQG9qnUxVriJcnNfWUhfoeU8Mjntkunt9ZnjBsartDSZz+MpIvZbuw7CHK2tjt6
# iHxmveRwPU1HtpOCMaAUai5A9+/33Oc0QFhoqa9nsWxMNEGYU7NvJyfYia7m1jC2
# JD938ngi2PKnNgKfTJFk/Sbms9Sa1gkowPHRbTgdXGXwboFMzK3tfLcxggIMMIIC
# CAIBATBaMEMxEzARBgoJkiaJk/IsZAEZFgNvcmcxFTATBgoJkiaJk/IsZAEZFgVu
# Y2dycDEVMBMGA1UEAxMMTkNHLU5DTFN1YkNBAhMQAAO1zPCELBcEplgxAAEAA7XM
# MA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIOQa2q055++m5ii3MLOx2bMtyoclDM3uK3Ei
# 4Aj0QxFfMA0GCSqGSIb3DQEBAQUABIIBAHlakHmTo7PHFBJixexD/lUmM14BzHiu
# vkrGW7ky+8W8k3PKJCaJYQdy09ELmjVGGv5kOUBstfWvYFZJyy8brC5PLPcvmFrS
# Rjtx4o2jCjgm8i7QIuchwtfOdmzt0kF2nD/3nvJ1MdCuOsoMQTiZKK1mha3tepiQ
# UZM8XJHJzABFv5trIc+v52oSZax9Y7VgxI2q6TCE8R/zxcy7c2YUnNGzoArDJ50p
# /wzM4NKsGgd0Z7iuf0YdfWz7vgcbOCGtlw4/ACeY24GmQEpPPa/4Vb7N5Ux2RvCC
# zFqFwEvseJDiTJnqOdBpuSRyCu65DtAQlDuWL4kNul23Pv/0sET3FP0=
# SIG # End signature block
