// ===== SOURCE 1: CBOs =====
let
    Source = Folder.Files("C:\CBOs"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File", each #"Transform File"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File", Table.ColumnNames(#"Transform File"(#"Sample File"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Batch ID", type text}, {"Temporary ID", Int64.Type}, {"Customer Number", Int64.Type}, {"Address Code", Int64.Type}, {"Customer Name", type text}, {"Job Number", Int64.Type}, {"Date", type date}, {"Temp First Name", type text}, {"Temp Last Name", type text}, {"Pay Type ID", type text}, {"Time Worked", type number}, {"Pay Rate", type number}, {"Pay Amount", type number}, {"PAM Time Billed", type number}, {"PAM Bill Rate", type number}, {"Total Fee", type number}, {"Invoice Number", type text}, {"Purchase Order Number", type text}, {"Invoice Adjustment", type text}, {"TRX Date", type date}, {"PAM Timesheet Number", type any}, {"Analyst", type text}, {"Delivery", type text}})
in
    #"Changed Type"
// ===== SOURCE 2: ANALYST MASTER =====
let
    Source = Folder.Files("C:\Analyst Master Query"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File (2)", each #"Transform File (2)"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File (2)"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File (2)", Table.ColumnNames(#"Transform File (2)"(#"Sample File (2)"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Customer Number", Int64.Type}, {"Customer Name", type text}, {"Analyst", type text}, {"TS Required", type text}, {"Delivery", type text}, {"Contact", type text}, {"Net Terms", type text}, {"Suppress", type text}})
in
    #"Changed Type"
// ===== MERGE 1 =====
let
    Source = Table.NestedJoin(#"Analyst Master Query", {"Customer Name"}, CBOs, {"Customer Name"}, "CBOs", JoinKind.LeftOuter),
    #"Removed Columns" = Table.RemoveColumns(Source,{"Source.Name", "TS Required", "Net Terms", "Suppress", "Contact"}),
    #"Reordered Columns" = Table.ReorderColumns(#"Removed Columns",{"Customer Number", "Customer Name", "CBOs", "Analyst", "Delivery"}),
    #"Expanded CBOs" = Table.ExpandTableColumn(#"Reordered Columns", "CBOs", {"Batch ID", "Temporary ID", "Address Code", "Job Number", "Date", "Temp First Name", "Temp Last Name", "Pay Type ID", "Time Worked", "Pay Rate", "Pay Amount", "PAM Time Billed", "PAM Bill Rate", "Total Fee", "Invoice Number", "Purchase Order Number", "Invoice Adjustment", "TRX Date", "PAM Timesheet Number"}, {"Batch ID", "Temporary ID", "Address Code", "Job Number", "Date", "Temp First Name", "Temp Last Name", "Pay Type ID", "Time Worked", "Pay Rate", "Pay Amount", "PAM Time Billed", "PAM Bill Rate", "Total Fee", "Invoice Number", "Purchase Order Number", "Invoice Adjustment", "TRX Date", "PAM Timesheet Number"}),
    #"Reordered Columns1" = Table.ReorderColumns(#"Expanded CBOs",{"Batch ID", "Temporary ID", "Customer Number", "Customer Name", "Address Code", "Job Number", "Date", "Temp First Name", "Temp Last Name", "Pay Type ID", "Time Worked", "Pay Rate", "Pay Amount", "PAM Time Billed", "PAM Bill Rate", "Total Fee", "Invoice Number", "Purchase Order Number", "Invoice Adjustment", "TRX Date", "PAM Timesheet Number", "Analyst", "Delivery"})
in
    #"Reordered Columns1"
// ===== SOURCE 3: EXPORTS FROM CENTREVIEWS =====
let
    Source = Folder.Files("C:\Exports from CentreView for Email Audit&Reconciliation"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File (3)", each #"Transform File (3)"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File (3)"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File (3)", Table.ColumnNames(#"Transform File (3)"(#"Sample File (3)"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Invoice Number", type text}, {"Invoice Total", type number}, {"Invoice Date", type date}, {"Customer Number", Int64.Type}, {"Customer Name", type text}, {"PO Number", type text}, {"Address Code", type text}, {"Due Date", type date}, {"Week End Date", type date}, {"Terms", type text}, {"Location", type text}, {"Batch ID", type datetime}, {"Date Created", type datetime}, {"Date Updated", type datetime}, {"Row ID", Int64.Type}, {"ExternalID", type text}, {"PAM Number", type any}, {"Version", Int64.Type}, {"DocumentID", type text}, {"", type any}})
in
    #"Changed Type"
// ===== MERGE 2 (FINAL) =====
let
    Source = Table.NestedJoin(Merge1, {"Invoice Number"}, #"Exports from CentreView for Email Audit&Reconciliation", {"Invoice Number"}, "Exports from CentreView for Email Audit&Reconciliation", JoinKind.LeftOuter),
    #"Expanded Exports from CentreView for Email Audit&Reconciliation" = Table.ExpandTableColumn(Source, "Exports from CentreView for Email Audit&Reconciliation", {"Invoice Number"}, {"Invoice Number.1"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded Exports from CentreView for Email Audit&Reconciliation",{{"Invoice Number.1", "CV Invoice Number"}}),
    #"Added Conditional Column" = Table.AddColumn(#"Renamed Columns", "Status", each if [Invoice Number] = null then "Not Created" else if [Invoice Number] = [CV Invoice Number] then "Sent" else "Check Email"),
    #"Replaced Value" = Table.ReplaceValue(#"Added Conditional Column",null,"(blank)",Replacer.ReplaceValue,{"Invoice Number"}),
    #"Replaced Errors" = Table.ReplaceErrorValues(#"Replaced Value", {{"Customer Number", null}}),
    #"Replaced Errors1" = Table.ReplaceErrorValues(#"Replaced Errors", {{"Address Code", null}})
in
    #"Replaced Errors1"
