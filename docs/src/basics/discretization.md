# Discretization Methods

For `generateJuMPcodes`, choose different discretization methods by passing name of method to `discretization`

## Single-step Method Supported

```math
f_i = f(x_i,y_i)
```

- *trapezoidal*

```math
y_{i+i}=y_i+\frac{h}{2}[f_i+f_{i+1}]\\
R[y]=-\frac{h^3}{12}y^{(3)}(\xi_i)
```

- *Amdams-Bashforth*

- *Amdams-Monlton*
