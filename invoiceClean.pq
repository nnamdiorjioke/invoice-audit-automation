// ===== SOURCE 1: TRANSACTION LEDGER =====
// Replaced local company path and format specifics with generic transaction indicators
let
    Source = Folder.Files("C:\Import_Data\Weekly_Transaction_Ledger"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File", each #"Transform File"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File", Table.ColumnNames(#"Transform File"(#"Sample File"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Batch ID", type text}, {"Tracking ID", Int64.Type}, {"Customer Number", Int64.Type}, {"Region Code", Int64.Type}, {"Customer Name", type text}, {"Job Number", Int64.Type}, {"Date", type date}, {"Employee First Name", type text}, {"Employee Last Name", type text}, {"Pay Type ID", type text}, {"Hours Worked", type number}, {"Pay Rate", type number}, {"Gross Pay Amount", type number}, {"System Time Billed", type number}, {"Bill Rate", type number}, {"Total Fee", type number}, {"Invoice Number", type text}, {"Purchase Order Number", type text}, {"Invoice Adjustment", type text}, {"Transaction Date", type date}, {"System Timesheet Number", type any}, {"Account Analyst", type text}, {"Delivery Method", type text}})
in
    #"Changed Type"

// ===== SOURCE 2: STAFF ROUTING MATRIX =====
// Anonymized routing reference table logic
let
    Source = Folder.Files("C:\Import_Data\Staff_Routing_Matrix"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File (2)", each #"Transform File (2)"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File (2)"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File (2)", Table.ColumnNames(#"Transform File (2)"(#"Sample File (2)"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Customer Number", Int64.Type}, {"Customer Name", type text}, {"Account Analyst", type text}, {"Documentation Required", type text}, {"Delivery Method", type text}, {"Primary Contact", type text}, {"Net Terms", type text}, {"Suppress Flag", type text}})
in
    #"Changed Type"

// ===== SOURCE 3: SYSTEM INVOICING EXPORTS =====
// Scrubbed third-party accounts payable application identity and custom markers
let
    Source = Folder.Files("C:\Import_Data\System_Invoicing_Exports"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File (3)", each #"Transform File (3)"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File (3)"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File (3)", Table.ColumnNames(#"Transform File (3)"(#"Sample File (3)"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Invoice Number", type text}, {"Invoice Total", type number}, {"Invoice Date", type date}, {"Customer Number", Int64.Type}, {"Customer Name", type text}, {"PO Number", type text}, {"Region Code", type text}, {"Due Date", type date}, {"Week End Date", type date}, {"Terms", type text}, {"Location", type text}, {"Batch ID", type datetime}, {"Date Created", type datetime}, {"Date Updated", type datetime}, {"Row ID", Int64.Type}, {"ExternalID", type text}, {"System Billing Number", type any}, {"Version", Int64.Type}, {"DocumentID", type text}, {"Metadata", type any}})
in
    #"Changed Type"

// ===== MERGE 1: CONSOLIDATING LEDGER WITH ROUTING =====
// Corrected join architecture to use numeric keys while avoiding descriptive overlap
let
    Source = Table.NestedJoin(#"Weekly_Transaction_Ledger", {"Customer Number"}, #"Staff_Routing_Matrix", {"Customer Number"}, "Staff_Routing_Matrix", JoinKind.LeftOuter),
    #"Expanded Matrix" = Table.ExpandTableColumn(Source, "Staff_Routing_Matrix", {"Account Analyst", "Delivery Method"}, {"Account Analyst", "Delivery Method"})
in
    #"Expanded Matrix"

// ===== MERGE 2: VERIFICATION ENGINE (FINAL) =====
// Processes cross-system delivery status evaluations using abstracted tracking variables
let
    Source = Table.NestedJoin(Merge1, {"Invoice Number"}, #"System_Invoicing_Exports", {"Invoice Number"}, "System_Invoicing_Exports", JoinKind.LeftOuter),
    #"Expanded Verification Keys" = Table.ExpandTableColumn(Source, "System_Invoicing_Exports", {"Invoice Number"}, {"Verified Invoice Number"}),
    #"Added Conditional Status" = Table.AddColumn(#"Expanded Verification Keys", "Status", each 
        if [Invoice Number] = null then "Not Created" 
        else if [Verified Invoice Number] <> null then "Sent" 
        else "Check Email"
    ),
    #"Cleaned Null Records" = Table.ReplaceValue(#"Added Conditional Status", null, "(blank)", Replacer.ReplaceValue, {"Invoice Number"}),
    #"Handled Errors Customer" = Table.ReplaceErrorValues(#"Cleaned Null Records", {{"Customer Number", null}}),
    #"Handled Errors Region" = Table.ReplaceErrorValues(#"Handled Errors Customer", {{"Region Code", null}})
in
    #"Handled Errors Region"
