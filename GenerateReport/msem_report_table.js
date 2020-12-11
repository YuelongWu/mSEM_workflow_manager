/* JS scripts used in Retake Manager reports */
/* Yuelong Wu, Feb 2019 */
function hide_show_table_colume(buttonObj){
    /*  The callback function to collapse/expand a column in the table.
        The table headers have the form:
        <th>
        <span class='colname'>
            colnname
        </span>
        <button onclick='hide_show_table_colume(this)'>
            -/+
        </button>
        </th>
        click the button will collapse/expand the corresponding collumn */
    var headerElement = buttonObj.previousElementSibling;  // get the header object
    var colName = headerElement.className;  // column name
    var crntState = headerElement.style.display;  // the current display state of the column
    var colElements = document.getElementsByClassName(colName); // Get the column
    var k;  // counter variable
    if (crntState == 'none') {
        for (k=0; k<colElements.length; k++){
            colElements[k].style.display = 'initial';  // show column
            buttonObj.innerHTML = '&#8863;';  // change icon to -
        }
    } else {
        for (k=0; k<colElements.length; k++){
            colElements[k].style.display = 'none';  // hide column
            buttonObj.innerHTML = '&#8862;';  // change icon to +
        }
    }
}

function hide_show_retake_sections(buttonObj){
    /*  The callback function to hide/show retaken sections
        Respond to the button (onclick) at the top of the page
    */
   var crntButtonStr = buttonObj.innerHTML;  // current state
   var retakenTRs = document.querySelectorAll('tr.retakSection, tr.discdSection');  // get all the retaken rows
   var k;   // counter variable
   if (crntButtonStr == 'Show sections to keep') {
       for (k=0; k<retakenTRs.length; k++){
           retakenTRs[k].style.display = 'none';
       }
       buttonObj.innerHTML = 'Show all the sections';
   } else {
       for (k=0; k<retakenTRs.length; k++){
            retakenTRs[k].style.display = 'table-row';
       }
       buttonObj.innerHTML = 'Show sections to keep';
   }
}

function sort_sections_by_batch_id(buttonObj){
    /*  The callback function to sort the sections based on batch or section name
    */
    var crntButtonStr = buttonObj.innerHTML;  // current state
    var table, rows, switching, i, x, y, shouldSwitch;
    table = document.getElementById("sectionTable");
    switching = true;
    if (crntButtonStr == 'Sort table by batch timestamp') {
        while (switching) {
            switching = false;
            rows = table.rows;
            for (i = 1; i < (rows.length - 1); i++) {
            shouldSwitch = false;
            x = rows[i].getElementsByClassName("bts")[0];
            y = rows[i + 1].getElementsByClassName("bts")[0];
            if (x.innerHTML > y.innerHTML) {
                shouldSwitch = true;
                break;
            }
            }
            if (shouldSwitch) {
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
            }
        }
        buttonObj.innerHTML = 'Sort table by section name';
    } else {
        while (switching) {
            switching = false;
            rows = table.rows;
            for (i = 1; i < (rows.length - 1); i++) {
            shouldSwitch = false;
            x = rows[i].getElementsByClassName("secid")[0];
            y = rows[i + 1].getElementsByClassName("secid")[0];
            if (x.innerHTML > y.innerHTML) {
                shouldSwitch = true;
                break;
            }
            }
            if (shouldSwitch) {
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
            }
        }
        buttonObj.innerHTML = 'Sort table by batch timestamp';
    }
}