*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.PDF
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Archive
Library    Dialogs
Library    RPA.Robocorp.Vault

*** Keywords ***
Download File
    [Arguments]    ${link}
    ${url}=    Get Value From User    Url for robot orders to be created?    ${link}
    Download    ${url}   ${CURDIR}\\exports\\downloads\\orders.csv    overwrite=True

Get Keys And Download File
    ${secret}=    Get Secret    Orders URL
    Download File    ${secret}[url]
Open Web Browser and Close Modal
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK

Fill Out Form
    [Arguments]    ${order}
    ${body}=    Convert To Integer    ${order}[Body]
    ${legs}=    Convert To Integer    ${order}[Legs]
    Select From List By value    id:head    ${order}[Head]
    Click Element    //input[@value=${body}]
    Scroll Element Into View    //*[@id="preview"]
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${legs}
    Input Text    //*[@placeholder="Shipping address"]    ${order}[Address]
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image
    Click Button    Order
    FOR    ${i}    IN RANGE    0    100
        ${sucessfullyOrdered}=    Is element visible    id:order-another
        Exit For Loop If    ${sucessfullyOrdered} == True
        Click Button    Order
    END

Take ScrnShot
    [Arguments]    ${order}
    Screenshot    id:robot-preview-image    ${CURDIR}\\exports\\receipts\\${order}[Order number].png

Save PDF
    [Arguments]    ${order}
    ${orderId}=    Convert To String  ${order}[Order number]
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}\\exports\\receipts\\${orderId}.pdf
    Add Watermark Image To Pdf    ${CURDIR}\\exports\\receipts\\${orderId}.png    ${CURDIR}\\exports\\receipts\\${orderId}.pdf    ${CURDIR}\\exports\\receipts\\${orderId}.pdf

Order Another robot
    Click Button    id:order-another
    Click Button    OK
    Wait Until Element Is Visible    id:head

Read Orders File
    ${orders}=    Read table from CSV    ${CURDIR}\\exports\\downloads\\orders.csv    header=True    delimiters=,
    FOR    ${row}    IN    @{orders}
        Fill Out Form    ${row}
        Take ScrnShot    ${row}
        Save PDF    ${row}
        Order Another robot
    END

Zip Folder
    Archive Folder With Zip    ${CURDIR}\\exports\\receipts    ${CURDIR}\\Output\\receipts.zip

*** Tasks ***
Open robotsparebinindustries
    Get Keys And Download File
    Open Web Browser and Close Modal
    Sleep    2
    Read Orders File
    Zip Folder
    [Teardown]    Close Browser
    