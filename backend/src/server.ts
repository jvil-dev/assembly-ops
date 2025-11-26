import app from "./app";
import authRoutes from "./routes/authRoutes";

const PORT = process.env.PORT || 3000;

// Routes
app.use("/auth", authRoutes);

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
