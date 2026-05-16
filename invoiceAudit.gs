function checkAllInvoices() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var lastRow = sheet.getLastRow();

  for (var i = 4; i <= lastRow; i++) {
    var invoiceCell = sheet.getRange(i, 5); // Column E
    var statusCell = sheet.getRange(i, 8); // Column H
    var invoiceNum = invoiceCell.getValue();
    var cvStatus = sheet.getRange(i, 6).getValue(); // Column F
    
    if (cvStatus == "Sent") {
      sheet.getRange(i, 8).setValue("Verified In System");
      sheet.getRange(i, 8).setBackground("c9c9c9");
      continue;
    }

    // if blank, mark not created
    if (invoiceNum == "" || invoiceNum == null || invoiceNum == "(blank)") {
      statusCell.setValue("Not Created");
      statusCell.setBackground("#ff9999"); // red
      continue; 
    }
    
    // Search Gmail for the invoice number
    var threads = GmailApp.search(invoiceNum);
    if (threads.length > 0) {
      Logger.log("Subject: " + threads[0].getMessages()[0].getSubject());
    }

    if (threads.length > 0){
      statusCell.setValue("Found & Sent");
      statusCell.setBackground("99ff99"); // green
    } else {
      statusCell.setValue("Not Found");
      statusCell.setBackground("#ffff99"); // yellow
    }
  }
}
