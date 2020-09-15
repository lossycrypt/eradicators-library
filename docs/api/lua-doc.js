function sort(id) {
  var table = document.getElementById(id).getElementsByClassName('brief-members')[0];

  var tb = table.tBodies[0], // use `<tbody>` to ignore `<thead>` and `<tfoot>` rows
      tr = Array.prototype.slice.call(tb.rows, 0), // put rows into array
      i;
  // reverse = -((+reverse) || -1);
  tr = tr.sort(function (a, b) { // sort rows
      return 1 // `-1 *` if want opposite order
          * (a.cells[0].textContent.trim() // using `.textContent.trim()` for test
              .localeCompare(b.cells[0].textContent.trim())
            );
  });
  for(i = 0; i < tr.length; ++i) tb.appendChild(tr[i]); 
}
