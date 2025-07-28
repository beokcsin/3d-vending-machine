'use client';

import { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
} from '@mui/material';
import { Print, Upload, CheckCircle, Error } from '@mui/icons-material';
import { useDropzone } from 'react-dropzone';
import axios from 'axios';

interface PrintJob {
  id: string;
  name: string;
  description: string;
  material: string;
  price: number;
  status: string;
  progressPercentage: number;
  createdAt: string;
}

export default function Home() {
  const [file, setFile] = useState<File | null>(null);
  const [jobName, setJobName] = useState('');
  const [description, setDescription] = useState('');
  const [material, setMaterial] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    accept: {
      'application/octet-stream': ['.stl', '.gcode'],
      'model/stl': ['.stl'],
    },
    maxFiles: 1,
    onDrop: (acceptedFiles) => {
      setFile(acceptedFiles[0]);
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file || !jobName || !material || !email) {
      setError('Please fill in all required fields and upload a file.');
      return;
    }

    setLoading(true);
    setError('');

    try {
      // In a real implementation, you'd upload to S3 first, then create the job
      const formData = new FormData();
      formData.append('file', file);
      formData.append('name', jobName);
      formData.append('description', description);
      formData.append('material', material);
      formData.append('customerEmail', email);
      if (phone) formData.append('customerPhone', phone);

      const response = await axios.post('/api/printjobs', {
        name: jobName,
        description,
        fileUrl: 'placeholder-url', // In real app, this would be the S3 URL
        fileName: file.name,
        fileSize: file.size,
        material,
        price: calculatePrice(material, file.size),
        estimatedPrintTimeMinutes: estimatePrintTime(file.size),
        customerEmail: email,
        customerPhone: phone,
      });

      setSuccess(true);
      setFile(null);
      setJobName('');
      setDescription('');
      setMaterial('');
      setEmail('');
      setPhone('');
    } catch (err) {
      setError('Failed to create print job. Please try again.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const calculatePrice = (material: string, fileSize: number): number => {
    const basePrice = 5.0;
    const sizeMultiplier = fileSize / (1024 * 1024) * 0.1; // $0.10 per MB
    const materialMultiplier = material === 'PLA' ? 1.0 : 1.5;
    return Math.round((basePrice + sizeMultiplier) * materialMultiplier * 100) / 100;
  };

  const estimatePrintTime = (fileSize: number): number => {
    // Rough estimate: 1 minute per MB
    return Math.max(30, Math.round(fileSize / (1024 * 1024)));
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h2" component="h1" gutterBottom align="center">
        3D Printing Vending Machine
      </Typography>
      <Typography variant="h5" component="h2" gutterBottom align="center" color="text.secondary">
        Upload your 3D model and get it printed!
      </Typography>

      <Grid container spacing={4} sx={{ mt: 4 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Create New Print Job
              </Typography>

              {error && (
                <Alert severity="error" sx={{ mb: 2 }}>
                  {error}
                </Alert>
              )}

              {success && (
                <Alert severity="success" sx={{ mb: 2 }}>
                  Print job created successfully! You will receive updates via email.
                </Alert>
              )}

              <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
                <Box
                  {...getRootProps()}
                  sx={{
                    border: '2px dashed',
                    borderColor: isDragActive ? 'primary.main' : 'grey.300',
                    borderRadius: 1,
                    p: 3,
                    textAlign: 'center',
                    cursor: 'pointer',
                    mb: 2,
                    backgroundColor: isDragActive ? 'action.hover' : 'background.paper',
                  }}
                >
                  <input {...getInputProps()} />
                  <Upload sx={{ fontSize: 48, color: 'text.secondary', mb: 1 }} />
                  <Typography variant="h6" gutterBottom>
                    {isDragActive ? 'Drop the file here' : 'Drag & drop a 3D file here'}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Supports .stl and .gcode files
                  </Typography>
                  {file && (
                    <Alert severity="info" sx={{ mt: 2 }}>
                      Selected: {file.name} ({(file.size / (1024 * 1024)).toFixed(2)} MB)
                    </Alert>
                  )}
                </Box>

                <TextField
                  fullWidth
                  label="Job Name"
                  value={jobName}
                  onChange={(e) => setJobName(e.target.value)}
                  required
                  sx={{ mb: 2 }}
                />

                <TextField
                  fullWidth
                  label="Description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  multiline
                  rows={3}
                  sx={{ mb: 2 }}
                />

                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Material</InputLabel>
                  <Select
                    value={material}
                    label="Material"
                    onChange={(e) => setMaterial(e.target.value)}
                    required
                  >
                    <MenuItem value="PLA">PLA</MenuItem>
                    <MenuItem value="ABS">ABS</MenuItem>
                    <MenuItem value="PETG">PETG</MenuItem>
                    <MenuItem value="TPU">TPU</MenuItem>
                  </Select>
                </FormControl>

                <TextField
                  fullWidth
                  label="Email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  sx={{ mb: 2 }}
                />

                <TextField
                  fullWidth
                  label="Phone (optional)"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  sx={{ mb: 2 }}
                />

                {file && material && (
                  <Alert severity="info" sx={{ mb: 2 }}>
                    Estimated Price: ${calculatePrice(material, file.size).toFixed(2)} | 
                    Estimated Time: {estimatePrintTime(file.size)} minutes
                  </Alert>
                )}

                <Button
                  type="submit"
                  variant="contained"
                  size="large"
                  fullWidth
                  disabled={loading || !file || !jobName || !material || !email}
                  startIcon={loading ? <CircularProgress size={20} /> : <Print />}
                >
                  {loading ? 'Creating Print Job...' : 'Create Print Job'}
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                How It Works
              </Typography>
              <Box sx={{ mt: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <CheckCircle color="primary" sx={{ mr: 1 }} />
                  <Typography>Upload your 3D model file (.stl or .gcode)</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <CheckCircle color="primary" sx={{ mr: 1 }} />
                  <Typography>Choose your preferred material</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <CheckCircle color="primary" sx={{ mr: 1 }} />
                  <Typography>Get instant price and time estimates</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <CheckCircle color="primary" sx={{ mr: 1 }} />
                  <Typography>Receive email updates on your print progress</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CheckCircle color="primary" sx={{ mr: 1 }} />
                  <Typography>Pick up your finished print when ready</Typography>
                </Box>
              </Box>

              <Box sx={{ mt: 4 }}>
                <Typography variant="h6" gutterBottom>
                  Available Materials
                </Typography>
                <Grid container spacing={1}>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      • PLA - $5.00 base
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      • ABS - $7.50 base
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      • PETG - $7.50 base
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      • TPU - $7.50 base
                    </Typography>
                  </Grid>
                </Grid>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Container>
  );
} 