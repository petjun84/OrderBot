*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    #auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get and log the value of the vault secrets using the Get Secret keyword
    ${csv}=    Get CSV URL From user
    Open the robot order website
    ${orders}=    Get orders    ${csv}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Clean Up TEMP directories


*** Keywords ***
Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    credentials
    # Note: In real robots, you should not print secrets to the log.
    # This is just for demonstration purposes. :)
    Log    ${secret}[username]
    Log    ${secret}[password]

Open the robot order website
    Open Browser    https://robotsparebinindustries.com/#/robot-order    edge

Get CSV URL From user
    Add text input    URL    label=Give URL of the CSV file    rows=5
    ${csv}=    Run dialog    on_top=TRUE
    RETURN    ${csv.URL}

Get orders
    [Arguments]    ${URL}
    Download    ${URL}    overwrite=True
    ${AllOrders}=    Read table from CSV    orders.csv
    RETURN    ${AllOrders}
    #https://robotsparebinindustries.com/orders.csv

Preview the robot
    Wait Until Element Is Visible    preview    timeout=10
    Click Button    preview

Close the annoying modal
    Wait Until Element Is Visible    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]

Fill the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //*[@class="form-control"]    ${row}[Legs]
    Input text    address    ${row}[Address]

 Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    //div[@id="receipt"]
    ${receipt_html}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${ordernumber}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}${ordernumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]
    Capture Element Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}robopics${/}${ordernumber}.png
    RETURN    ${OUTPUT_DIR}${/}robopics${/}${ordernumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    rpa.pdf.Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    Close All Pdfs

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts${/}
    ...    ${zip_file_name}

Submit the order
    Click Button    order
    Wait Until Element Is Visible    order-another

Go to order another robot
    Wait Until Element Is Visible    order-another
    Click button    order-another

Clean Up TEMP directories
    Empty Directory    ${OUTPUT_DIR}${/}receipts${/}
    Empty Directory    ${OUTPUT_DIR}${/}robopics${/}
