// Autocompletado de productos en ventas
document.addEventListener("DOMContentLoaded", function() {
  let searchTimeout = null;
  let currentResults = [];
  let activeResultsList = null;

  // Delegación de eventos para campos de autocompletado
  document.addEventListener('input', function(e) {
    if (!e.target.classList.contains('producto-autocomplete')) return;
    
    const input = e.target;
    const query = input.value.trim();
    
    // Limpiar timeout anterior
    clearTimeout(searchTimeout);
    
    // Limpiar resultados si la búsqueda es muy corta
    if (query.length < 2) {
      clearResults();
      return;
    }
    
    // Esperar 300ms antes de buscar
    searchTimeout = setTimeout(() => {
      buscarProductos(query, input);
    }, 300);
  });

  // Cerrar resultados al hacer clic fuera
  document.addEventListener('click', function(e) {
    if (!e.target.closest('.autocomplete-container')) {
      clearResults();
    }
  });

  function buscarProductos(query, input) {
    fetch(`/buscar_productos?q=${encodeURIComponent(query)}`)
      .then(response => response.json())
      .then(productos => {
        mostrarResultados(productos, input);
      })
      .catch(error => {
        console.error('Error buscando productos:', error);
      });
  }

  function mostrarResultados(productos, input) {
    clearResults();
    
    if (productos.length === 0) {
      const noResults = document.createElement('div');
      noResults.className = 'autocomplete-results p-2 text-muted';
      noResults.textContent = 'No se encontraron productos';
      input.parentElement.appendChild(noResults);
      return;
    }
    
    currentResults = productos;
    const resultsList = document.createElement('div');
    resultsList.className = 'autocomplete-results';
    
    productos.forEach((producto, index) => {
      const item = document.createElement('div');
      item.className = 'autocomplete-item';
      item.innerHTML = `
        <div><strong>${producto.titulo}</strong></div>
        <div class="text-muted small">${producto.autor} - ${producto.categoria}</div>
        <div class="text-muted small">Stock: ${producto.stock} | Precio: $${producto.precio}</div>
      `;
      
      item.addEventListener('click', () => {
        seleccionarProducto(producto, input);
      });
      
      resultsList.appendChild(item);
    });
    
    input.parentElement.appendChild(resultsList);
    activeResultsList = resultsList;
  }

  function seleccionarProducto(producto, input) {
    // Encontrar el campo hidden del producto_id
    const renglon = input.closest('.renglon-venta');
    const productoIdField = renglon.querySelector('.producto-id-field');
    const precioField = renglon.querySelector('.precio-input');
    const cantidadField = renglon.querySelector('.cantidad-input');
    const productoInfo = renglon.querySelector('.producto-info');
    
    // Setear valores
    if (productoIdField) productoIdField.value = producto.id;
    if (precioField) precioField.value = producto.precio;
    if (cantidadField && !cantidadField.value) cantidadField.value = 1;
    
    // Mostrar información del producto seleccionado
    input.value = producto.titulo;
    if (productoInfo) {
      productoInfo.innerHTML = `<strong>${producto.autor}</strong> - Stock: ${producto.stock} - $${producto.precio}`;
    }
    
    // Calcular subtotal
    calcularSubtotal(renglon);
    
    // Limpiar resultados
    clearResults();
    
    // Calcular total general
    calcularTotalGeneral();
  }

  function calcularSubtotal(renglon) {
    const cantidad = parseFloat(renglon.querySelector('.cantidad-input')?.value || 0);
    const precio = parseFloat(renglon.querySelector('.precio-input')?.value || 0);
    const subtotalInput = renglon.querySelector('.subtotal-input');
    
    if (subtotalInput) {
      subtotalInput.value = (cantidad * precio).toFixed(2);
    }
  }

  function calcularTotalGeneral() {
    let total = 0;
    document.querySelectorAll('.renglon-venta').forEach(renglon => {
      const destroyFlag = renglon.querySelector('.destroy-flag');
      if (destroyFlag && destroyFlag.value === "1") return;
      
      const subtotalInput = renglon.querySelector('.subtotal-input');
      if (subtotalInput) {
        total += parseFloat(subtotalInput.value || 0);
      }
    });
    
    const totalField = document.getElementById('venta_total');
    if (totalField) {
      totalField.value = total.toFixed(2);
    }
  }

  function clearResults() {
    const allResults = document.querySelectorAll('.autocomplete-results');
    allResults.forEach(r => r.remove());
    activeResultsList = null;
  }

  // Recalcular subtotales cuando cambie cantidad
  document.addEventListener('input', function(e) {
    if (e.target.classList.contains('cantidad-input')) {
      const renglon = e.target.closest('.renglon-venta');
      calcularSubtotal(renglon);
      calcularTotalGeneral();
    }
  });
});
