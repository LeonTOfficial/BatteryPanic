import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import { getCurrentPage } from './content.ts';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App page={getCurrentPage()} />
  </StrictMode>,
);
